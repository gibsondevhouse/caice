import Foundation

protocol ChatService: Sendable {
    func updateModel(_ model: String)
    func updateContextWindow(_ tokens: Int?)

    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String

    func send(
        conversation: [ChatMessage],
        newMessage: String,
        onDelta: @escaping (String) async -> Void
    ) async throws -> String
}

extension ChatService {
    func updateModel(_ model: String) {
        _ = model
    }

    func updateContextWindow(_ tokens: Int?) {
        _ = tokens
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String,
        onDelta: @escaping (String) async -> Void
    ) async throws -> String {
        let response = try await send(
            conversation: conversation,
            newMessage: newMessage
        )
        await onDelta(response)
        return response
    }
}
