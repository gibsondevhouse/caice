import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage]
    @Published var composerText: String = ""
    @Published private(set) var isSending: Bool = false
    @Published private(set) var streamingRevision: Int = 0
    @Published var errorText: String?

    private let service: ChatService
    private let defaults: UserDefaults
    private let session: URLSession
    private var sendTask: Task<String, Error>?
    private var didAttemptModelReconciliation = false

    init(
        service: ChatService,
        initialMessages: [ChatMessage] = [],
        defaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        self.service = service
        self.messages = initialMessages
        self.defaults = defaults
        self.session = session
    }

    func updateModel(_ model: String) {
        let sanitized = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return }

        defaults.set(sanitized, forKey: ChatServiceFactory.ollamaModelDefaultsKey)
        service.updateModel(sanitized)
    }

    func reconcileModelIfNeeded(endpointURL: URL, runtimeModelName: String) async -> String? {
        guard !didAttemptModelReconciliation else { return nil }
        didAttemptModelReconciliation = true

        guard let installedModels = try? await fetchInstalledModelNames(endpointURL: endpointURL),
              let firstInstalledModel = installedModels.first else {
            return nil
        }

        let needsReconcile = runtimeModelName == ChatServiceFactory.automaticModelLabel
            || !installedModels.contains(runtimeModelName)

        guard needsReconcile else { return nil }

        updateModel(firstInstalledModel)
        return firstInstalledModel
    }

    func sendCurrentMessage() async {
        let outgoingText = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !outgoingText.isEmpty else { return }
        guard !isSending else { return }

        errorText = nil
        isSending = true
        composerText = ""

        let userMessage = ChatMessage(role: .user, text: outgoingText)
        messages.append(userMessage)
        let conversation = messages
        let assistantMessageID = appendAssistantPlaceholder()

        sendTask = Task {
            try await service.send(
                conversation: conversation,
                newMessage: outgoingText,
                onDelta: { delta in
                    await MainActor.run {
                        self.appendAssistantDelta(delta, to: assistantMessageID)
                    }
                }
            )
        }

        do {
            let responseText = try await sendTask?.value ?? ""

            if assistantMessageText(for: assistantMessageID).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                replaceAssistantMessage(id: assistantMessageID, text: responseText)
            }
        } catch is CancellationError {
            if assistantMessageText(for: assistantMessageID).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                removeMessage(id: assistantMessageID)
            }
            errorText = nil
        } catch {
            let partial = assistantMessageText(for: assistantMessageID).trimmingCharacters(in: .whitespacesAndNewlines)
            if partial.isEmpty {
                removeMessage(id: assistantMessageID)
            }
            errorText = userFacingErrorText(for: error)
        }

        sendTask = nil
        isSending = false
    }

    func cancelCurrentSend() {
        guard isSending else { return }
        sendTask?.cancel()
    }

    func beginNewChat() {
        cancelCurrentSend()
        messages = []
        composerText = ""
        errorText = nil
        isSending = false
    }

    func prefillComposer(with text: String) {
        composerText = text
    }

    private func appendAssistantPlaceholder() -> UUID {
        let id = UUID()
        messages.append(ChatMessage(id: id, role: .assistant, text: ""))
        return id
    }

    private func appendAssistantDelta(_ delta: String, to id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text.append(delta)
        streamingRevision += 1
    }

    private func replaceAssistantMessage(id: UUID, text: String) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text = text
    }

    private func assistantMessageText(for id: UUID) -> String {
        messages.first(where: { $0.id == id })?.text ?? ""
    }

    private func removeMessage(id: UUID) {
        messages.removeAll { $0.id == id }
    }

    private func fetchInstalledModelNames(endpointURL: URL) async throws -> [String] {
        var request = URLRequest(url: endpointURL.appending(path: "api/tags"))
        request.httpMethod = "GET"
        request.timeoutInterval = 3.0

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return []
        }

        let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return decoded.models.map(\.name)
    }

    private func userFacingErrorText(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }

        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty {
            return description
        }

        return "Could not send message."
    }
}
