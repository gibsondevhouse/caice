import SwiftUI

#if DEBUG
struct AppComponentsPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                AppPageHeader(title: "Design System", subtitle: "Reusable UI Components")

                AppSection(title: "Page Header", subtitle: "Main screen titles") {
                    AppPageHeader(
                        title: "Chat",
                        subtitle: "Local | Llama 2 | Ready",
                        titleFont: .largeTitle.weight(.semibold),
                        subtitleFont: .subheadline
                    )
                }

                AppSection(title: "Cards", subtitle: "Material container") {
                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Card Content")
                                .font(.headline)
                            Text("This is a material card with stroke and shadow")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                AppSection(title: "Status Badge", subtitle: "Semantic status indicators") {
                    HStack(spacing: 12) {
                        AppStatusBadge(title: "Online", color: AppTheme.Accent.success, systemImage: "checkmark.circle.fill")
                        AppStatusBadge(title: "Busy", color: AppTheme.Accent.warning, systemImage: "exclamationmark.circle.fill")
                        AppStatusBadge(title: "Error", color: AppTheme.Accent.critical, systemImage: "xmark.circle.fill")
                    }
                }

                AppSection(title: "Key-Value Block", subtitle: "Metadata display") {
                    AppKeyValueBlock(title: "Model", value: "Llama 2 13B")
                }

                AppSection(title: "Inline Notices", subtitle: "Contextual alerts") {
                    AppInlineNotice(text: "Connection established to local Ollama", tint: AppTheme.Accent.info, systemImage: "info.circle")
                }

                AppSection(title: "Success Message", subtitle: "Positive feedback") {
                    AppSuccessMessage(text: "Settings saved successfully")
                }

                AppSection(title: "Error Message", subtitle: "Error feedback") {
                    AppErrorMessage(text: "Failed to connect to Ollama runtime")
                }

                AppSection(title: "Alert Badges", subtitle: "Warning indicators") {
                    HStack {
                        AppAlertBadge(text: "Warning", accent: AppTheme.Accent.warning)
                        AppAlertBadge(text: "Critical", accent: AppTheme.Accent.critical, systemImage: "xmark.circle.fill")
                    }
                }

                AppSection(title: "Action Tile", subtitle: "Selectable state") {
                    VStack(spacing: 8) {
                        AppActionTile(isSelected: false, action: {}) {
                            Text("Unselected Tile")
                        }
                        AppActionTile(isSelected: true, action: {}) {
                            Text("Selected Tile")
                        }
                    }
                }

                AppSection(title: "Sidebar Row", subtitle: "Navigation item") {
                    VStack(spacing: 8) {
                        AppSidebarRow(
                            title: "Chat",
                            subtitle: "5 messages",
                            systemImage: "bubble.left.and.bubble.right.fill",
                            isSelected: true,
                            action: {}
                        )
                        AppSidebarRow(
                            title: "Models",
                            subtitle: "Ollama",
                            systemImage: "slider.horizontal.3",
                            isSelected: false,
                            action: {}
                        )
                    }
                }
            }
            .padding(.horizontal, AppTheme.Layout.pageHorizontalPadding)
            .padding(.vertical, AppTheme.Layout.pageVerticalPadding)
        }
        .background(AppTheme.Surface.windowBackground)
    }
}

#Preview {
    AppComponentsPreview()
        .frame(width: 600, height: 1200)
}
#endif
