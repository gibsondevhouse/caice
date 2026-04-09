import SwiftUI

struct AppPageHeader: View {
    let title: String
    let subtitle: String?
    var titleFont: Font = AppTheme.Typography.pageTitle
    var subtitleFont: Font = AppTheme.Typography.pageSubtitle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(titleFont)
                .lineSpacing(3)

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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
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
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(AppTheme.Surface.panelGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .strokeBorder(AppTheme.Surface.stroke, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .strokeBorder(AppTheme.Surface.softOverlay, lineWidth: 0.5)
                    .padding(1)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.13),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(1)
                    .allowsHitTesting(false)
            }
            .shadow(
                color: AppTheme.Shadow.color,
                radius: AppTheme.Shadow.radius,
                x: AppTheme.Shadow.x,
                y: AppTheme.Shadow.y
            )
            .shadow(
                color: AppTheme.Shadow.ambient,
                radius: AppTheme.Shadow.ambientRadius,
                x: 0,
                y: AppTheme.Shadow.ambientY
            )
    }
}
