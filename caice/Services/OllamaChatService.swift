import Foundation

final class OllamaChatService: ChatService {
    static let autoModelMarker = "__caice_auto__"

    let baseURL: URL
    let session: URLSession
    private let lock = NSLock()
    private var configuredModelName: String
    private var configuredContextWindowTokens: Int?

    init(
        configuration: Configuration,
        session: URLSession = .shared
    ) {
        self.baseURL = configuration.baseURL
        self.configuredModelName = configuration.model
        self.configuredContextWindowTokens = configuration.contextWindowTokens
        self.session = session
    }

    func updateModel(_ model: String) {
        let sanitized = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return }

        lock.lock()
        configuredModelName = sanitized
        lock.unlock()
    }

    func updateContextWindow(_ tokens: Int?) {
        if let tokens, tokens < 256 {
            return
        }

        lock.lock()
        configuredContextWindowTokens = tokens
        lock.unlock()
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        try await send(
            conversation: conversation,
            newMessage: newMessage,
            onDelta: { _ in }
        )
    }

    func currentModelName() -> String {
        lock.lock()
        defer { lock.unlock() }
        return configuredModelName
    }

    func currentContextWindowTokens() -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return configuredContextWindowTokens
    }

}