import SwiftUI

struct AppKeyValueBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.captionStrong)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            Text(value)
                .font(AppTheme.Typography.prominentBody)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Layout.tilePadding)
        .padding(.vertical, AppTheme.Layout.tilePadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                .fill(AppTheme.Surface.subtleFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                .strokeBorder(AppTheme.Surface.tileStroke, lineWidth: 1)
        )
    }
}

struct RuntimeSummaryView: View {
    let providerName: String
    let modelName: String
    let statusSummary: String
    let endpoint: String?
    let messageCount: Int
    let isSending: Bool
    let lastError: String?

    var body: some View {
        List {
            Section("Provider") {
                AppKeyValueBlock(title: "Backend", value: providerName)
                AppKeyValueBlock(title: "Model", value: modelName)
                AppKeyValueBlock(title: "Status", value: statusSummary)
                if let endpoint {
                    AppKeyValueBlock(title: "Endpoint", value: endpoint)
                }
            }

            Section("Conversation") {
                AppKeyValueBlock(title: "Messages", value: "\(messageCount)")
                AppKeyValueBlock(title: "Sending", value: isSending ? "In progress" : "Idle")
                if let lastError {
                    AppKeyValueBlock(title: "Last Error", value: lastError)
                }
            }
        }
        .navigationTitle("Models")
    }
}
