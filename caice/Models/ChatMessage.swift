import Foundation

struct ChatMessage: Identifiable, Equatable, Sendable {
    enum Role: String, Sendable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    var text: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}
