import SwiftUI

struct AppPageHeader: View {
    let title: String
    let subtitle: String?
    var titleFont: Font = AppTheme.Typography.pageTitle
    var subtitleFont: Font = AppTheme.Typography.pageSubtitle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(titleFont)
                .lineSpacing(2)

            if let subtitle {
                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.sectionTitle)
                    .lineSpacing(1.5)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
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
                    .fill(.thinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(AppTheme.Surface.panelBackground.opacity(0.55))
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
