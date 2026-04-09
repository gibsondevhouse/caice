import Foundation

protocol ConversationStore: Sendable {
    func load() -> ConversationStoreSnapshot
    func save(_ snapshot: ConversationStoreSnapshot)
}

struct ConversationStoreSnapshot: Equatable, Sendable {
    var threads: [ChatThread]
    var selectedThreadID: UUID?
}

struct UserDefaultsConversationStore: ConversationStore {
    private enum Keys {
        static let threads = "caice.conversations.threads"
        static let selectedThreadID = "caice.conversations.selectedThreadID"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> ConversationStoreSnapshot {
        let threads: [ChatThread]
        if let data = defaults.data(forKey: Keys.threads),
           let decoded = try? decoder.decode([ChatThread].self, from: data) {
            threads = decoded
        } else {
            threads = []
        }

        let selectedThreadID: UUID?
        if let raw = defaults.string(forKey: Keys.selectedThreadID) {
            selectedThreadID = UUID(uuidString: raw)
        } else {
            selectedThreadID = nil
        }

        return ConversationStoreSnapshot(threads: threads, selectedThreadID: selectedThreadID)
    }

    func save(_ snapshot: ConversationStoreSnapshot) {
        guard let threadData = try? encoder.encode(snapshot.threads) else {
            return
        }

        defaults.set(threadData, forKey: Keys.threads)

        if let selectedThreadID = snapshot.selectedThreadID {
            defaults.set(selectedThreadID.uuidString, forKey: Keys.selectedThreadID)
        } else {
            defaults.removeObject(forKey: Keys.selectedThreadID)
        }
    }
}
