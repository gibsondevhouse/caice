import Foundation

struct MockChatService: ChatService {
    var latencyNanoseconds: UInt64 = 350_000_000

    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        try await Task.sleep(nanoseconds: latencyNanoseconds)

        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Please type a message and I will respond."
        }

        return "Mock assistant: \(trimmed)"
    }
}
