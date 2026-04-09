import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var threads: [ChatThread]
    @Published private(set) var selectedThreadID: UUID?
    @Published var composerText: String = "" {
        didSet {
            persistDraftForSelectedThread()
        }
    }
    @Published var isSending: Bool = false
    @Published var streamingRevision: Int = 0
    @Published var errorText: String?

    let service: ChatService
    let defaults: UserDefaults
    let session: URLSession
    let conversationStore: ConversationStore
    var sendTask: Task<String, Error>?
    var activeSendThreadID: UUID?
    var didAttemptModelReconciliation = false

    init(
        service: ChatService,
        initialMessages: [ChatMessage] = [],
        defaults: UserDefaults = .standard,
        session: URLSession = .shared,
        conversationStore: ConversationStore? = nil
    ) {
        self.service = service
        self.defaults = defaults
        self.session = session
        self.conversationStore = conversationStore ?? UserDefaultsConversationStore(defaults: defaults)

        let snapshot = self.conversationStore.load()
        if snapshot.threads.isEmpty {
            if initialMessages.isEmpty {
                self.threads = []
            } else {
                self.threads = [
                    ChatThread(title: "Imported Chat", messages: initialMessages)
                ]
            }
            self.selectedThreadID = self.threads.first?.id
            if !self.threads.isEmpty {
                persistSnapshot()
            }
        } else {
            self.threads = snapshot.threads
            self.selectedThreadID = snapshot.selectedThreadID ?? snapshot.threads.first?.id
            sortThreadsByRecency()
            if threadIndex(for: self.selectedThreadID) == nil {
                self.selectedThreadID = self.threads.first?.id
            }
        }

        composerText = selectedThread?.draftText ?? ""
    }

    var messages: [ChatMessage] {
        selectedThread?.messages ?? []
    }

    var selectedThreadTitle: String {
        selectedThread?.title ?? "Chat"
    }

    var threadSummaries: [ChatThreadSummary] {
        threads.map { thread in
            ChatThreadSummary(
                id: thread.id,
                title: thread.title,
                lastMessagePreview: thread.lastMessagePreview,
                messageCount: thread.messages.count,
                updatedAt: thread.updatedAt
            )
        }
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
        _ = createThread(select: true)
        errorText = nil
        isSending = false
    }

    @discardableResult
    func createThread(title: String = "New Chat", select: Bool = true) -> UUID {
        let thread = ChatThread(title: sanitizedTitle(title))
        threads.insert(thread, at: 0)
        if select {
            selectedThreadID = thread.id
            composerText = thread.draftText
        }
        persistSnapshot()
        return thread.id
    }

    func selectThread(_ id: UUID) {
        guard selectedThreadID != id,
              threadIndex(for: id) != nil else {
            return
        }

        selectedThreadID = id
        composerText = selectedThread?.draftText ?? ""
        errorText = nil
        persistSnapshot()
    }

    func renameThread(id: UUID, to title: String) {
        guard let index = threadIndex(for: id) else { return }
        threads[index].title = sanitizedTitle(title)
        threads[index].hasUserDefinedTitle = true
        persistSnapshot()
    }

    func threadTitle(for id: UUID?) -> String {
        guard let index = threadIndex(for: id) else {
            return "Conversation"
        }
        return threads[index].title
    }

    func shouldConfirmDelete(for id: UUID) -> Bool {
        guard let index = threadIndex(for: id) else { return false }
        return !threads[index].messages.isEmpty
    }

    @discardableResult
    func deleteThread(id: UUID) -> ChatThread? {
        guard let removedIndex = threadIndex(for: id) else { return nil }

        if activeSendThreadID == id {
            cancelCurrentSend()
        }

        let deletedThread = threads.remove(at: removedIndex)

        if threads.isEmpty {
            selectedThreadID = nil
            composerText = ""
        } else if selectedThreadID == id {
            selectedThreadID = threads.first?.id
            composerText = selectedThread?.draftText ?? ""
        }

        persistSnapshot()
        return deletedThread
    }

    func restoreDeletedThread(_ thread: ChatThread) {
        threads.removeAll { $0.id == thread.id }
        threads.insert(thread, at: 0)
        selectedThreadID = thread.id
        composerText = thread.draftText
        sortThreadsByRecency()
        persistSnapshot()
    }

    func prefillComposer(with text: String) {
        composerText = text
    }

    func ensureSelectedThreadID() -> UUID {
        if let selectedThreadID,
           threadIndex(for: selectedThreadID) != nil {
            return selectedThreadID
        }

        let createdThreadID = createThread(select: true)
        selectedThreadID = createdThreadID
        return createdThreadID
    }

    func threadIndex(for id: UUID?) -> Int? {
        guard let id else { return nil }
        return threads.firstIndex(where: { $0.id == id })
    }

    var selectedThread: ChatThread? {
        guard let index = threadIndex(for: selectedThreadID) else { return nil }
        return threads[index]
    }

    func appendMessage(_ message: ChatMessage, to threadID: UUID) {
        guard let index = threadIndex(for: threadID) else { return }
        if message.role == .user,
           !threads[index].hasUserDefinedTitle,
           threads[index].title == "New Chat" {
            threads[index].title = autoTitle(from: message.text)
        }
        threads[index].messages.append(message)
        threads[index].updatedAt = Date()
        sortThreadsByRecency()
        persistSnapshot()
    }

    func appendAssistantPlaceholder(in threadID: UUID) -> UUID {
        let placeholderID = UUID()
        appendMessage(ChatMessage(id: placeholderID, role: .assistant, text: ""), to: threadID)
        return placeholderID
    }

    func appendAssistantDelta(_ delta: String, to messageID: UUID, in threadID: UUID) {
        guard let threadIndex = threadIndex(for: threadID),
              let messageIndex = threads[threadIndex].messages.firstIndex(where: { $0.id == messageID }) else {
            return
        }

        threads[threadIndex].messages[messageIndex].text.append(delta)
        threads[threadIndex].updatedAt = Date()
        sortThreadsByRecency()
        persistSnapshot()
        streamingRevision += 1
    }

    func replaceAssistantMessage(id messageID: UUID, text: String, in threadID: UUID) {
        guard let threadIndex = threadIndex(for: threadID),
              let messageIndex = threads[threadIndex].messages.firstIndex(where: { $0.id == messageID }) else {
            return
        }

        threads[threadIndex].messages[messageIndex].text = text
        threads[threadIndex].updatedAt = Date()
        sortThreadsByRecency()
        persistSnapshot()
    }

    func assistantMessageText(for messageID: UUID, in threadID: UUID) -> String {
        guard let threadIndex = threadIndex(for: threadID) else { return "" }
        return threads[threadIndex].messages.first(where: { $0.id == messageID })?.text ?? ""
    }

    func removeMessage(id messageID: UUID, from threadID: UUID) {
        guard let threadIndex = threadIndex(for: threadID) else { return }
        threads[threadIndex].messages.removeAll { $0.id == messageID }
        threads[threadIndex].updatedAt = Date()
        sortThreadsByRecency()
        persistSnapshot()
    }

    func conversation(for threadID: UUID) -> [ChatMessage] {
        guard let threadIndex = threadIndex(for: threadID) else { return [] }
        return threads[threadIndex].messages
    }

    private func persistSnapshot() {
        conversationStore.save(
            ConversationStoreSnapshot(
                threads: threads,
                selectedThreadID: selectedThreadID
            )
        )
    }

    private func sortThreadsByRecency() {
        threads.sort { $0.updatedAt > $1.updatedAt }
    }

    private func sanitizedTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "New Chat"
        }
        return String(trimmed.prefix(60))
    }

    private func persistDraftForSelectedThread() {
        guard let index = threadIndex(for: selectedThreadID) else { return }
        if threads[index].draftText == composerText {
            return
        }
        threads[index].draftText = composerText
        persistSnapshot()
    }

    private func autoTitle(from messageText: String) -> String {
        // 1. Collapse all whitespace and newlines into single spaces
        let collapsed = messageText
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !collapsed.isEmpty else {
            return "New Chat"
        }

        // 2. Strip one noisy leading prefix (conservative, case-insensitive)
        var working = collapsed
        let noisyPrefixes = [
            "can you ", "could you ", "would you ", "will you ",
            "please ", "help me ", "i need to ", "i need ",
            "i want to ", "i want ", "i'd like to ", "i'd like ",
            "tell me ", "show me ", "explain ", "describe ",
            "what is ", "what are ", "what's the ", "what's ",
            "how do i ", "how to ", "how can i "
        ]
        let lowercased = working.lowercased()
        for prefix in noisyPrefixes {
            if lowercased.hasPrefix(prefix) {
                let candidate = String(working.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespaces)
                if !candidate.isEmpty {
                    working = candidate
                }
                break
            }
        }

        // 3. Guard against pure-punctuation result with no meaningful content
        guard working.contains(where: { $0.isLetter || $0.isNumber }) else {
            return "New Chat"
        }

        // 4. Normalize generated titles into readable title case.
        working = titleCase(working)

        // 5. Clean truncation at word boundary when over limit
        let limit = 42
        guard working.count > limit else {
            return working
        }
        let truncated = String(working.prefix(limit))
        if let lastSpace = truncated.lastIndex(of: " ") {
            let candidate = String(truncated[truncated.startIndex..<lastSpace])
            if candidate.count >= limit / 2 {
                return candidate
            }
        }
        return truncated
    }

    private func titleCase(_ title: String) -> String {
        let lowercaseJoiners: Set<String> = [
            "a", "an", "and", "as", "at", "by", "for", "in", "of", "on", "or", "the", "to", "vs", "via"
        ]

        let words = title.split(separator: " ", omittingEmptySubsequences: true)

        return words.enumerated().map { index, token in
            let word = String(token)
            let letters = word.filter { $0.isLetter }
            if letters.isEmpty {
                return word
            }

            // Preserve words that already include internal uppercase characters (e.g. SwiftUI).
            if word.dropFirst().contains(where: { $0.isUppercase }) {
                return word
            }

            let lowercase = word.lowercased()
            if index > 0 && lowercaseJoiners.contains(lowercase) {
                return lowercase
            }

            let first = lowercase.prefix(1).uppercased()
            return first + lowercase.dropFirst()
        }
        .joined(separator: " ")
    }

}
