import Foundation

protocol ChatService: Sendable {
    func updateModel(_ model: String)

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
