import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage]
    @Published var composerText: String = ""
    @Published var isSending: Bool = false
    @Published var streamingRevision: Int = 0
    @Published var errorText: String?

    let service: ChatService
    let defaults: UserDefaults
    let session: URLSession
    var sendTask: Task<String, Error>?
    var didAttemptModelReconciliation = false

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

    func updateContextWindow(_ tokens: Int?) {
        guard let tokens else {
            defaults.removeObject(forKey: ChatServiceFactory.ollamaContextWindowDefaultsKey)
            service.updateContextWindow(nil)
            return
        }

        guard tokens >= 256 else { return }

        defaults.set(tokens, forKey: ChatServiceFactory.ollamaContextWindowDefaultsKey)
        service.updateContextWindow(tokens)
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

}
