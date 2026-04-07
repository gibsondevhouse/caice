import SwiftUI

struct ProviderDetailPaneView: View {
    let runtime: ChatRuntimeDescriptor
    let messageCount: Int
    let isSending: Bool
    let lastError: String?
    let onSelectModel: (String) -> Void
    let onSelectContextWindow: (Int?) -> Void

    var body: some View {
        if runtime.provider == .ollama,
           let endpointURL = runtime.endpointURL {
            OllamaSettingsView(
                endpointURL: endpointURL,
                selectedModelName: runtime.modelName,
                selectedContextWindowTokens: runtime.contextWindowTokens,
                providerName: runtime.providerName,
                statusSummary: runtime.statusSummary,
                messageCount: messageCount,
                isSending: isSending,
                lastError: lastError,
                onSelectModel: onSelectModel,
                onSelectContextWindow: onSelectContextWindow
            )
        } else {
            RuntimeSummaryView(
                providerName: runtime.providerName,
                modelName: runtime.modelName,
                statusSummary: runtime.statusSummary,
                endpoint: runtime.endpoint,
                messageCount: messageCount,
                isSending: isSending,
                lastError: lastError
            )
        }
    }
}
