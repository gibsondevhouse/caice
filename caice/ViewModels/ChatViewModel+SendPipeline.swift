import Foundation

extension ChatViewModel {

    func sendCurrentMessage() async {
        let outgoingText = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        await sendMessage(displayText: outgoingText, modelPrompt: outgoingText, clearComposer: true)
    }

    func sendSuggestionAction(displayText: String, modelPrompt: String) async {
        let sanitizedDisplay = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedPrompt = modelPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        await sendMessage(displayText: sanitizedDisplay, modelPrompt: sanitizedPrompt, clearComposer: false)
    }

    private func sendMessage(displayText: String, modelPrompt: String, clearComposer: Bool) async {
        guard !modelPrompt.isEmpty else { return }
        guard !isSending else { return }

        let threadID = ensureSelectedThreadID()

        errorText = nil
        isSending = true
        if clearComposer {
            composerText = ""
        }
        activeSendThreadID = threadID

        let resolvedDisplayText = displayText.isEmpty ? modelPrompt : displayText
        let userMessage = ChatMessage(role: .user, text: resolvedDisplayText)
        appendMessage(userMessage, to: threadID)
        let conversation = self.conversation(for: threadID)
        let assistantMessageID = appendAssistantPlaceholder(in: threadID)

        sendTask = Task {
            try await service.send(
                conversation: conversation,
                newMessage: modelPrompt,
                onDelta: { delta in
                    await MainActor.run {
                        self.appendAssistantDelta(delta, to: assistantMessageID, in: threadID)
                    }
                }
            )
        }

        do {
            let responseText = try await sendTask?.value ?? ""

            if assistantMessageText(for: assistantMessageID, in: threadID).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                replaceAssistantMessage(id: assistantMessageID, text: responseText, in: threadID)
            }
        } catch is CancellationError {
            if assistantMessageText(for: assistantMessageID, in: threadID).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                removeMessage(id: assistantMessageID, from: threadID)
            }
            errorText = nil
        } catch {
            let partial = assistantMessageText(for: assistantMessageID, in: threadID).trimmingCharacters(in: .whitespacesAndNewlines)
            if partial.isEmpty {
                removeMessage(id: assistantMessageID, from: threadID)
            }
            errorText = userFacingErrorText(for: error)
        }

        sendTask = nil
        activeSendThreadID = nil
        isSending = false
    }

    func cancelCurrentSend() {
        guard isSending else { return }
        sendTask?.cancel()
    }
}
