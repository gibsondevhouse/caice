import Foundation

extension ChatViewModel {

    func sendCurrentMessage() async {
        let outgoingText = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !outgoingText.isEmpty else { return }
        guard !isSending else { return }

        errorText = nil
        isSending = true
        composerText = ""

        let userMessage = ChatMessage(role: .user, text: outgoingText)
        messages.append(userMessage)
        let conversation = messages
        let assistantMessageID = appendAssistantPlaceholder()

        sendTask = Task {
            try await service.send(
                conversation: conversation,
                newMessage: outgoingText,
                onDelta: { delta in
                    await MainActor.run {
                        self.appendAssistantDelta(delta, to: assistantMessageID)
                    }
                }
            )
        }

        do {
            let responseText = try await sendTask?.value ?? ""

            if assistantMessageText(for: assistantMessageID).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                replaceAssistantMessage(id: assistantMessageID, text: responseText)
            }
        } catch is CancellationError {
            if assistantMessageText(for: assistantMessageID).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                removeMessage(id: assistantMessageID)
            }
            errorText = nil
        } catch {
            let partial = assistantMessageText(for: assistantMessageID).trimmingCharacters(in: .whitespacesAndNewlines)
            if partial.isEmpty {
                removeMessage(id: assistantMessageID)
            }
            errorText = userFacingErrorText(for: error)
        }

        sendTask = nil
        isSending = false
    }

    func cancelCurrentSend() {
        guard isSending else { return }
        sendTask?.cancel()
    }

    func appendAssistantPlaceholder() -> UUID {
        let id = UUID()
        messages.append(ChatMessage(id: id, role: .assistant, text: ""))
        return id
    }

    func appendAssistantDelta(_ delta: String, to id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text.append(delta)
        streamingRevision += 1
    }

    func replaceAssistantMessage(id: UUID, text: String) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text = text
    }

    func assistantMessageText(for id: UUID) -> String {
        messages.first(where: { $0.id == id })?.text ?? ""
    }

    func removeMessage(id: UUID) {
        messages.removeAll { $0.id == id }
    }
}
