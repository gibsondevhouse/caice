import SwiftUI

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
