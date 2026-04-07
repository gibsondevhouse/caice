import SwiftUI

struct AppKeyValueBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(value)
                .font(AppTheme.Typography.prominentBody)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Layout.tilePadding)
        .padding(.vertical, AppTheme.Layout.tilePadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                .fill(AppTheme.Surface.subtleFill)
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
