import SwiftUI

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
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                                .lineLimit(2)

                            Text(activeContextSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(2)
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
                                    .lineSpacing(2)
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
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
