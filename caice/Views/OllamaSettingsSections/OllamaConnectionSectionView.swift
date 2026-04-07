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
