import SwiftUI

struct OllamaSettingsView: View {
    @StateObject private var viewModel: OllamaSettingsViewModel

    private let providerName: String
    private let statusSummary: String
    private let messageCount: Int
    private let isSending: Bool
    private let lastError: String?

    init(
        endpointURL: URL,
        selectedModelName: String,
        providerName: String,
        statusSummary: String,
        messageCount: Int,
        isSending: Bool,
        lastError: String?,
        onSelectModel: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: OllamaSettingsViewModel(
                endpointURL: endpointURL,
                selectedModelName: selectedModelName,
                onConfiguredModelChange: onSelectModel
            )
        )
        self.providerName = providerName
        self.statusSummary = statusSummary
        self.messageCount = messageCount
        self.isSending = isSending
        self.lastError = lastError
    }

    var body: some View {
        List {
            Section("Service") {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.serviceStatus.systemImage)
                        .foregroundStyle(serviceStatusColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.serviceStatus.title)
                            .font(.headline)
                        if let statusDetailText = viewModel.statusDetailText {
                            Text(statusDetailText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                LabeledContent("Endpoint", value: viewModel.endpointURL.absoluteString)
                LabeledContent("Provider", value: providerName)
                LabeledContent("Runtime", value: statusSummary)

                if let lastCheckedAt = viewModel.lastCheckedAt {
                    LabeledContent("Last Checked") {
                        Text(lastCheckedAt, style: .time)
                    }
                }

                ControlGroup {
                    Button("Connect") {
                        Task {
                            await viewModel.startOllama()
                        }
                    }
                    .disabled(!viewModel.canStartService)

                    Button("Reconnect") {
                        Task {
                            await viewModel.restartOllama()
                        }
                    }
                    .disabled(!viewModel.canRestartService)

                    Button("Refresh Status") {
                        Task {
                            await viewModel.refreshStatus()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }

                if let errorText = viewModel.errorText {
                    Text(errorText)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            Section("Model Configuration") {
                LabeledContent("Configured Model", value: viewModel.selectedModelName)

                if viewModel.hasLoadedModels && !viewModel.configuredModelInstalled {
                    Label(
                        "\(viewModel.selectedModelName) is not installed in your local Ollama runtime.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }
            }

            Section {
                if viewModel.isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Refreshing local models…")
                            .foregroundStyle(.secondary)
                    }
                } else if viewModel.availableModels.isEmpty {
                    ContentUnavailableView(
                        "No Local Models",
                        systemImage: "shippingbox",
                        description: Text("These models come directly from your local Ollama runtime.")
                    )
                    .foregroundStyle(.secondary)
                } else {
                    Text("These are the models installed in your local Ollama runtime.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    OllamaModelRows(
                        models: viewModel.availableModels,
                        selectedModelName: viewModel.selectedModelName
                    ) { modelName in
                        viewModel.selectConfiguredModel(modelName)
                    }
                }
            } header: {
                Text("Installed Models")
            }

            Section("Session") {
                LabeledContent("Messages", value: "\(messageCount)")
                LabeledContent("Sending", value: isSending ? "In progress" : "Idle")
                if let lastError {
                    LabeledContent("Last Error", value: lastError)
                }
            }
        }
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

    private var serviceStatusColor: Color {
        switch viewModel.serviceStatus {
        case .checking:
            return .secondary
        case .offline:
            return .orange
        case .starting, .restarting:
            return .blue
        case .running:
            return .green
        }
    }
}

private struct OllamaModelRows: View {
    let models: [OllamaSettingsViewModel.ModelInfo]
    let selectedModelName: String
    let onSelectModel: (String) -> Void

    var body: some View {
        SwiftUI.ForEach<[OllamaSettingsViewModel.ModelInfo], String, OllamaModelRow>(
            models,
            id: \.id
        ) { model in
            OllamaModelRow(
                model: model,
                isSelected: model.name == selectedModelName,
                onSelect: {
                    onSelectModel(model.name)
                }
            )
        }
    }
}

private struct OllamaModelRow: View {
    let model: OllamaSettingsViewModel.ModelInfo
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                if let detailDescription = model.detailDescription {
                    Text(detailDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let metadataDescription = model.metadataDescription {
                    Text(metadataDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Label("Active", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.accentColor)
            } else {
                Button("Use") {
                    onSelect()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}