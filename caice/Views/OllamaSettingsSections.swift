import SwiftUI

struct OllamaConnectionSectionView: View {
    let statusTitle: String
    let statusColor: Color
    let statusSystemImage: String
    let statusDetailText: String?
    let errorText: String?
    let endpointURL: URL
    let providerName: String
    let statusSummary: String
    let lastCheckedLabel: String
    let primaryActionTitle: String
    let isLoading: Bool
    let canStartService: Bool
    let canRestartService: Bool
    let onPrimaryAction: () -> Void
    let onRefresh: () -> Void

    private let metadataColumns = [
        GridItem(.flexible(minimum: 220), spacing: 12, alignment: .leading),
        GridItem(.flexible(minimum: 220), spacing: 12, alignment: .leading)
    ]

    var body: some View {
        AppSection(title: "Connection", subtitle: "Current runtime status and endpoint health.") {
            AppCard {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            AppStatusBadge(
                                title: statusTitle,
                                color: statusColor,
                                systemImage: statusSystemImage
                            )

                            if let statusDetailText {
                                Text(statusDetailText)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Spacer(minLength: 20)

                        VStack(alignment: .trailing, spacing: 10) {
                            Button(primaryActionTitle) {
                                onPrimaryAction()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(isLoading || (!canStartService && !canRestartService))

                            Button("Refresh Status") {
                                onRefresh()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .disabled(isLoading)
                        }
                    }

                    if let errorText {
                        AppInlineNotice(text: errorText, tint: AppTheme.Accent.critical, systemImage: "exclamationmark.triangle.fill")
                    }

                    LazyVGrid(columns: metadataColumns, alignment: .leading, spacing: 12) {
                        AppKeyValueBlock(title: "Endpoint", value: endpointURL.absoluteString)
                        AppKeyValueBlock(title: "Provider", value: providerName)
                        AppKeyValueBlock(title: "Runtime", value: statusSummary)
                        AppKeyValueBlock(title: "Last Checked", value: lastCheckedLabel)
                    }
                }
            }
        }
    }
}

struct OllamaActiveModelSectionView: View {
    let selectedModelName: String
    let activeContextSummary: String
    let hasLoadedModels: Bool
    let configuredModelInstalled: Bool
    let currentContextWindowValue: Int?
    let contextPresets: [ContextPreset]
    @Binding var contextWindowText: String
    let onSelectContextPreset: (Int?) -> Void
    let onApplyContextWindow: () -> Void
    let onResetContextWindow: () -> Void

    var body: some View {
        AppSection(title: "Active Model", subtitle: "Pick the installed model to chat with and choose a context size that matches your machine.") {
            AppCard {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(selectedModelName)
                                .font(.system(size: 28, weight: .semibold))

                            Text(activeContextSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 12)

                        if hasLoadedModels && !configuredModelInstalled {
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
                                        onSelectContextPreset(preset.value)
                                    }
                                )
                            }
                        }

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
                                    onApplyContextWindow()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Reset") {
                                    contextWindowText = ""
                                    onResetContextWindow()
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
}

struct OllamaInstalledModelsSectionView: View {
    let isLoading: Bool
    let availableModels: [OllamaSettingsViewModel.ModelInfo]
    let selectedModelName: String
    let onSelectModel: (String) -> Void

    var body: some View {
        AppSection(title: "Installed Models", subtitle: "Choose from models reported directly by your local Ollama runtime.") {
            if isLoading && availableModels.isEmpty {
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
            } else if availableModels.isEmpty {
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
                    ForEach(availableModels) { model in
                        OllamaModelCard(
                            model: model,
                            isSelected: model.name == selectedModelName,
                            onSelect: {
                                onSelectModel(model.name)
                            }
                        )
                    }
                }
            }
        }
    }
}

struct OllamaAdvancedSectionView: View {
    @Binding var isExpanded: Bool
    let messageCount: Int
    let isSending: Bool
    let selectedModelName: String
    let contextWindowText: String
    let lastError: String?
    let endpointURL: URL

    private let metadataColumns = [
        GridItem(.flexible(minimum: 220), spacing: 12, alignment: .leading),
        GridItem(.flexible(minimum: 220), spacing: 12, alignment: .leading)
    ]

    var body: some View {
        AppSection(title: "Advanced", subtitle: "Diagnostics and raw runtime details.") {
            AppCard {
                DisclosureGroup(isExpanded: $isExpanded) {
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()

                        LazyVGrid(columns: metadataColumns, alignment: .leading, spacing: 12) {
                            AppKeyValueBlock(title: "Messages", value: "\(messageCount)")
                            AppKeyValueBlock(title: "Sending", value: isSending ? "In progress" : "Idle")
                            AppKeyValueBlock(title: "Selected Model", value: selectedModelName)
                            AppKeyValueBlock(
                                title: "Raw Context",
                                value: contextWindowText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Automatic" : "\(contextWindowText) tokens"
                            )
                        }

                        if let lastError {
                            AppInlineNotice(text: lastError, tint: AppTheme.Accent.warning, systemImage: "info.circle.fill")
                        }

                        AppKeyValueBlock(title: "Endpoint URL", value: endpointURL.absoluteString)
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
}
