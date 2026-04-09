import Foundation

struct ChatThread: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var title: String
    var hasUserDefinedTitle: Bool
    var messages: [ChatMessage]
    var draftText: String
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case hasUserDefinedTitle
        case messages
        case draftText
        case createdAt
        case updatedAt
    }

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        hasUserDefinedTitle: Bool = false,
        messages: [ChatMessage] = [],
        draftText: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.hasUserDefinedTitle = hasUserDefinedTitle
        self.messages = messages
        self.draftText = draftText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "New Chat"
        hasUserDefinedTitle = try container.decodeIfPresent(Bool.self, forKey: .hasUserDefinedTitle) ?? false
        messages = try container.decodeIfPresent([ChatMessage].self, forKey: .messages) ?? []
        draftText = try container.decodeIfPresent(String.self, forKey: .draftText) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    var lastMessagePreview: String {
        let text = messages.last?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty {
            return "No messages yet"
        }
        return text
    }
}

struct ChatThreadSummary: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let lastMessagePreview: String
    let messageCount: Int
    let updatedAt: Date
}
