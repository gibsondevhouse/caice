import SwiftUI

struct OllamaSettingsView: View {
    @StateObject private var viewModel: OllamaSettingsViewModel
    @State private var contextWindowText: String
    @State private var isAdvancedExpanded = false

    private let providerName: String
    private let statusSummary: String
    private let messageCount: Int
    private let isSending: Bool
    private let lastError: String?
    private let onSelectContextWindow: (Int?) -> Void

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

    private var pageHeader: some View {
        AppPageHeader(
            title: "Ollama",
            subtitle: "Tune your local runtime for speed, memory use, and model selection without dropping into daemon-level tooling."
        )
    }

    private var connectionSection: some View {
        OllamaConnectionSectionView(
            statusTitle: viewModel.serviceStatus.title,
            statusColor: serviceStatusColor,
            statusSystemImage: viewModel.serviceStatus.systemImage,
            statusDetailText: viewModel.statusDetailText,
            errorText: viewModel.errorText,
            endpointURL: viewModel.endpointURL,
            providerName: providerName,
            statusSummary: statusSummary,
            lastCheckedLabel: lastCheckedLabel,
            primaryActionTitle: primaryConnectionActionTitle,
            isLoading: viewModel.isLoading,
            canStartService: viewModel.canStartService,
            canRestartService: viewModel.canRestartService,
            onPrimaryAction: {
                Task {
                    await performPrimaryConnectionAction()
                }
            },
            onRefresh: {
                Task {
                    await viewModel.refreshStatus()
                }
            }
        )
    }

    private var activeModelSection: some View {
        OllamaActiveModelSectionView(
            selectedModelName: viewModel.selectedModelName,
            activeContextSummary: activeContextSummary,
            hasLoadedModels: viewModel.hasLoadedModels,
            configuredModelInstalled: viewModel.configuredModelInstalled,
            currentContextWindowValue: currentContextWindowValue,
            contextPresets: contextPresets,
            contextWindowText: $contextWindowText,
            onSelectContextPreset: onSelectContextWindow,
            onApplyContextWindow: applyContextWindow,
            onResetContextWindow: {
                onSelectContextWindow(nil)
            }
        )
    }

    private var installedModelsSection: some View {
        OllamaInstalledModelsSectionView(
            isLoading: viewModel.isLoading,
            availableModels: viewModel.availableModels,
            selectedModelName: viewModel.selectedModelName,
            onSelectModel: { modelName in
                viewModel.selectConfiguredModel(modelName)
            }
        )
    }

    private var advancedSection: some View {
        OllamaAdvancedSectionView(
            isExpanded: $isAdvancedExpanded,
            messageCount: messageCount,
            isSending: isSending,
            selectedModelName: viewModel.selectedModelName,
            contextWindowText: contextWindowText,
            lastError: lastError,
            endpointURL: viewModel.endpointURL
        )
    }

    private var currentContextWindowValue: Int? {
        let sanitized = contextWindowText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Int(sanitized), parsed >= 256 else {
            return nil
        }
        return parsed
    }

    private var activeContextSummary: String {
        if let currentContextWindowValue {
            return "Context window set to \(humanReadableTokenCount(currentContextWindowValue))"
        }

        return "Context window is automatic"
    }

    private var primaryConnectionActionTitle: String {
        "Reconnect"
    }

    private func performPrimaryConnectionAction() async {
        if viewModel.canStartService {
            await viewModel.startOllama()
            return
        }

        if viewModel.canRestartService {
            await viewModel.restartOllama()
        }
    }

    private var lastCheckedLabel: String {
        guard let lastCheckedAt = viewModel.lastCheckedAt else {
            return "Not checked yet"
        }

        return lastCheckedAt.formatted(date: .omitted, time: .shortened)
    }

    private var serviceStatusColor: Color {
        switch viewModel.serviceStatus {
        case .checking:
            return AppTheme.Accent.neutral
        case .offline:
            return AppTheme.Accent.warning
        case .starting, .restarting:
            return AppTheme.Accent.info
        case .running:
            return AppTheme.Accent.success
        }
    }

    private var contextPresets: [ContextPreset] {
        [
            ContextPreset(title: "Auto", subtitle: "Balanced", value: nil),
            ContextPreset(title: "4K", subtitle: "Fastest", value: 4096),
            ContextPreset(title: "8K", subtitle: "Recommended", value: 8192),
            ContextPreset(title: "16K", subtitle: "Longer Memory", value: 16384)
        ]
    }

    private func applyContextWindow() {
        let sanitized = contextWindowText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else {
            onSelectContextWindow(nil)
            return
        }

        guard let parsed = Int(sanitized), parsed >= 256 else {
            return
        }

        contextWindowText = String(parsed)
        onSelectContextWindow(parsed)
    }

    private func humanReadableTokenCount(_ count: Int) -> String {
        if count >= 1000 {
            return "\(count / 1000)K tokens"
        }

        return "\(count) tokens"
    }
}
