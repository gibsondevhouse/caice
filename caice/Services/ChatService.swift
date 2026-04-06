import Foundation

protocol ChatService: Sendable {
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
