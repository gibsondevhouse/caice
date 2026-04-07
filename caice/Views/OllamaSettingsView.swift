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
        AppSection(title: "Connection", subtitle: "Current runtime status and endpoint health.") {
            AppCard {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 16) {
                        connectionSummary
                        Spacer(minLength: 20)
                        connectionActions
                    }

                    if let errorText = viewModel.errorText {
                        AppInlineNotice(text: errorText, tint: AppTheme.Accent.critical, systemImage: "exclamationmark.triangle.fill")
                    }

                    connectionMetadata
                }
            }
        }
    }

    private var connectionSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppStatusBadge(
                title: viewModel.serviceStatus.title,
                color: serviceStatusColor,
                systemImage: viewModel.serviceStatus.systemImage
            )

            if let statusDetailText = viewModel.statusDetailText {
                Text(statusDetailText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var connectionActions: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Button(primaryConnectionActionTitle) {
                Task {
                    await performPrimaryConnectionAction()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading || (!viewModel.canStartService && !viewModel.canRestartService))

            Button("Refresh Status") {
                Task {
                    await viewModel.refreshStatus()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.isLoading)
        }
    }

    private var connectionMetadata: some View {
        LazyVGrid(columns: connectionMetadataColumns, alignment: .leading, spacing: 12) {
            AppKeyValueBlock(title: "Endpoint", value: viewModel.endpointURL.absoluteString)
            AppKeyValueBlock(title: "Provider", value: providerName)
            AppKeyValueBlock(title: "Runtime", value: statusSummary)
            AppKeyValueBlock(title: "Last Checked", value: lastCheckedLabel)
        }
    }

    private var activeModelSection: some View {
        AppSection(title: "Active Model", subtitle: "Pick the installed model to chat with and choose a context size that matches your machine.") {
            AppCard {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.selectedModelName)
                                .font(.system(size: 28, weight: .semibold))

                            Text(activeContextSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 12)

                        if viewModel.hasLoadedModels && !viewModel.configuredModelInstalled {
                            AppStatusBadge(
                                title: "Not Installed",
                                color: AppTheme.Accent.warning,
                                systemImage: "exclamationmark.triangle.fill"
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Context Window")
                            .font(.headline)

                        presetRow

                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Custom Token Limit")
                                    .font(.subheadline.weight(.medium))

                                Text("Use a smaller window for faster responses and lower memory pressure.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 16)

                            HStack(spacing: 10) {
                                TextField("Custom", text: $contextWindowText)
#if os(iOS)
                                    .keyboardType(.numberPad)
#endif
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 110)

                                Button("Set") {
                                    applyContextWindow()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Reset") {
                                    contextWindowText = ""
                                    onSelectContextWindow(nil)
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        Text("Lower settings like 4K or 8K keep Qwen responsive on 16 GB Macs. Larger windows preserve more history but raise KV cache memory and can force CPU spillover.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var installedModelsSection: some View {
        AppSection(title: "Installed Models", subtitle: "Choose from models reported directly by your local Ollama runtime.") {
            if viewModel.isLoading && viewModel.availableModels.isEmpty {
                AppCard {
                    HStack(spacing: 12) {
                        ProgressView()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Refreshing local models")
                                .font(.headline)
                            Text("Caice is fetching the installed model list from your Ollama daemon.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else if viewModel.availableModels.isEmpty {
                AppCard {
                    ContentUnavailableView(
                        "No Local Models",
                        systemImage: "shippingbox",
                        description: Text("Install or pull a model in Ollama, then refresh the runtime status here.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(viewModel.availableModels) { model in
                        OllamaModelCard(
                            model: model,
                            isSelected: model.name == viewModel.selectedModelName,
                            onSelect: {
                                viewModel.selectConfiguredModel(model.name)
                            }
                        )
                    }
                }
            }
        }
    }

    private var advancedSection: some View {
        AppSection(title: "Advanced", subtitle: "Diagnostics and raw runtime details.") {
            AppCard {
                DisclosureGroup(isExpanded: $isAdvancedExpanded) {
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()

                        LazyVGrid(columns: connectionMetadataColumns, alignment: .leading, spacing: 12) {
                            AppKeyValueBlock(title: "Messages", value: "\(messageCount)")
                            AppKeyValueBlock(title: "Sending", value: isSending ? "In progress" : "Idle")
                            AppKeyValueBlock(title: "Selected Model", value: viewModel.selectedModelName)
                            AppKeyValueBlock(title: "Raw Context", value: contextWindowText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Automatic" : "\(contextWindowText) tokens")
                        }

                        if let lastError {
                            AppInlineNotice(text: lastError, tint: AppTheme.Accent.warning, systemImage: "info.circle.fill")
                        }

                        AppKeyValueBlock(title: "Endpoint URL", value: viewModel.endpointURL.absoluteString)
                    }
                    .padding(.top, 6)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Runtime Diagnostics")
                            .font(.headline)

                        Text("Expand for session telemetry, raw endpoint details, and the currently applied model configuration.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .disclosureGroupStyle(.automatic)
            }
        }
    }

    private var presetRow: some View {
        HStack(spacing: 10) {
            ForEach(contextPresets) { preset in
                ContextPresetButton(
                    title: preset.title,
                    subtitle: preset.subtitle,
                    isSelected: currentContextWindowValue == preset.value,
                    action: {
                        if let value = preset.value {
                            contextWindowText = String(value)
                        } else {
                            contextWindowText = ""
                        }
                        onSelectContextWindow(preset.value)
                    }
                )
            }
        }
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

    private var connectionMetadataColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 220), spacing: 12, alignment: .leading),
            GridItem(.flexible(minimum: 220), spacing: 12, alignment: .leading)
        ]
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

private struct ContextPreset: Identifiable {
    let title: String
    let subtitle: String
    let value: Int?

    var id: String { title }
}

private struct ContextPresetButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        AppActionTile(isSelected: isSelected, action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.accentColor.opacity(0.8) : .secondary)
            }
        }
    }
}

private struct OllamaModelCard: View {
    let model: OllamaSettingsViewModel.ModelInfo
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 10) {
                        Text(model.name)
                            .font(.title3.weight(.semibold))

                        if isSelected {
                            AppStatusBadge(title: "Active", color: .accentColor, systemImage: "checkmark.circle.fill")
                        }
                    }

                    if let detailDescription = model.detailDescription {
                        Text(detailDescription)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    if let metadataDescription = model.metadataDescription {
                        Text(metadataDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 20)

                VStack(alignment: .trailing, spacing: 8) {
                    if isSelected {
                        Text("Installed and in use")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if isSelected {
                        Button("Selected") {
                            onSelect()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(true)
                    } else {
                        Button("Use Model") {
                            onSelect()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
        }
    }
}