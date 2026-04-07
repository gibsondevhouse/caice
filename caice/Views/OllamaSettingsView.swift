import SwiftUI

struct OllamaSettingsView: View {
    @StateObject var viewModel: OllamaSettingsViewModel
    @State var contextWindowText: String
    @State var isAdvancedExpanded = false

    let providerName: String
    let statusSummary: String
    let messageCount: Int
    let isSending: Bool
    let lastError: String?
    let onSelectContextWindow: (Int?) -> Void

    init(
        endpointURL: URL,
        selectedModelName: String,
        selectedContextWindowTokens: Int?,
        providerName: String,
        statusSummary: String,
        messageCount: Int,
        isSending: Bool,
        lastError: String?,
        onSelectModel: @escaping (String) -> Void = { _ in },
        onSelectContextWindow: @escaping (Int?) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: OllamaSettingsViewModel(
                endpointURL: endpointURL,
                selectedModelName: selectedModelName,
                onConfiguredModelChange: onSelectModel
            )
        )
        _contextWindowText = State(initialValue: selectedContextWindowTokens.map(String.init) ?? "")
        self.providerName = providerName
        self.statusSummary = statusSummary
        self.messageCount = messageCount
        self.isSending = isSending
        self.lastError = lastError
        self.onSelectContextWindow = onSelectContextWindow
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {
                pageHeader
                connectionSection
                activeModelSection
                installedModelsSection
                advancedSection
            }
            .frame(maxWidth: AppTheme.Layout.settingsContentWidth, alignment: .leading)
            .padding(.horizontal, AppTheme.Layout.pageHorizontalPadding)
            .padding(.vertical, AppTheme.Layout.pageVerticalPadding)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.Surface.windowBackground)
        .navigationTitle("Ollama")
        .task {
            await viewModel.loadModelsIfNeeded()
        }
        .toolbar {
            ToolbarItem {
                Button {
                    Task {
                        await viewModel.refreshStatus()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }

}
