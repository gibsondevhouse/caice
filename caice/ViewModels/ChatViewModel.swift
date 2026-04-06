import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage]
    @Published var composerText: String = ""
    @Published private(set) var isSending: Bool = false
    @Published var errorText: String?

    private let service: ChatService

    init(
        service: ChatService,
        initialMessages: [ChatMessage] = []
    ) {
        self.service = service
        self.messages = initialMessages
    }

    func updateOllamaModel(_ model: String) {
        guard let ollamaService = service as? OllamaChatService else { return }
        ollamaService.updateModel(model)
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

        do {
            let responseText = try await service.send(
                conversation: conversation,
                newMessage: outgoingText,
                onDelta: { delta in
                    await MainActor.run {
                        self.appendAssistantDelta(delta, to: assistantMessageID)
                    }
                }
            )

            if assistantMessageText(for: assistantMessageID).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                replaceAssistantMessage(id: assistantMessageID, text: responseText)
            }
        } catch {
            removeMessage(id: assistantMessageID)
            errorText = userFacingErrorText(for: error)
        }

        isSending = false
    }

    private func appendAssistantPlaceholder() -> UUID {
        let id = UUID()
        messages.append(ChatMessage(id: id, role: .assistant, text: ""))
        return id
    }

    private func appendAssistantDelta(_ delta: String, to id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text.append(delta)
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
