import SwiftUI

struct AppPageHeader: View {
    let title: String
    let subtitle: String?
    var titleFont: Font = AppTheme.Typography.pageTitle
    var subtitleFont: Font = AppTheme.Typography.pageSubtitle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(titleFont)

            if let subtitle {
                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AppSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.sectionTitle)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
    }
}

struct AppCard<Content: View>: View {
    private let padding: CGFloat
    @ViewBuilder private let content: Content

    init(
        padding: CGFloat = AppTheme.Layout.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .strokeBorder(AppTheme.Surface.stroke, lineWidth: 1)
            )
            .shadow(
                color: AppTheme.Shadow.color,
                radius: AppTheme.Shadow.radius,
                x: AppTheme.Shadow.x,
                y: AppTheme.Shadow.y
            )
    }
}

struct AppStatusBadge: View {
    let title: String
    let color: Color
    let systemImage: String

    init(title: String, color: Color, systemImage: String) {
        self.title = title
        self.color = color
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(color.opacity(0.22), lineWidth: 1)
        )
    }
}

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

struct AppInlineNotice: View {
    let text: String
    let tint: Color
    let systemImage: String

    init(text: String, tint: Color, systemImage: String) {
        self.text = text
        self.tint = tint
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .padding(.top, 2)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppTheme.Layout.tilePadding)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .fill(tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .strokeBorder(tint.opacity(0.16), lineWidth: 1)
        )
    }
}

struct AppActionTile<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Layout.tilePadding)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.12) : AppTheme.Surface.subtleFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.45) : AppTheme.Surface.tileStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct AppSidebarRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AppSuccessMessage: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.Accent.success)
                .padding(.top, 2)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppTheme.Layout.tilePadding)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .fill(AppTheme.Accent.success.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .strokeBorder(AppTheme.Accent.success.opacity(0.16), lineWidth: 1)
        )
    }
}

struct AppErrorMessage: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(AppTheme.Accent.critical)
                .padding(.top, 2)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppTheme.Layout.tilePadding)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .fill(AppTheme.Accent.critical.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .strokeBorder(AppTheme.Accent.critical.opacity(0.16), lineWidth: 1)
        )
    }
}

struct AppAlertBadge: View {
    let text: String
    let accent: Color
    let systemImage: String

    init(text: String, accent: Color = AppTheme.Accent.warning, systemImage: String = "exclamationmark.triangle.fill") {
        self.text = text
        self.accent = accent
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(accent.opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(accent.opacity(0.22), lineWidth: 1)
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

#Preview("Design System Components", traits: .fixedLayout(width: 600, height: 1200)) {
    AppComponentsPreview()
}
#endif