import SwiftUI

enum AppTheme {
    enum Accent {
        static let success = Color.green
        static let warning = Color.orange
        static let info = Color.blue
        static let critical = Color.red
        static let neutral = Color.secondary
    }

    enum Layout {
        static let sectionSpacing: CGFloat = 30
        static let cardPadding: CGFloat = 24
        static let tilePadding: CGFloat = 14
        static let compactTilePadding: CGFloat = 12
        static let chatContentWidth: CGFloat = 1020
        static let settingsContentWidth: CGFloat = 920
        static let pageHorizontalPadding: CGFloat = 34
        static let pageVerticalPadding: CGFloat = 30
        static let contentGutter: CGFloat = 36
    }

    enum CornerRadius {
        static let card: CGFloat = 22
        static let tile: CGFloat = 16
        static let compactTile: CGFloat = 14
        static let bubble: CGFloat = 16
        static let sidebarTile: CGFloat = 12
    }

    enum Typography {
        static let pageTitle = Font.system(size: 34, weight: .semibold)
        static let heroTitle = Font.system(size: 44, weight: .semibold, design: .rounded)
        static let pageSubtitle = Font.title3.weight(.medium)
        static let sectionTitle = Font.title3.weight(.semibold)
        static let prominentBody = Font.body.weight(.medium)
        static let bodyLeading = Font.body
        static let captionStrong = Font.caption.weight(.semibold)
    }

    enum Shadow {
        static let color = Color.black.opacity(0.06)
        static let radius: CGFloat = 18
        static let x: CGFloat = 0
        static let y: CGFloat = 7
    }

    enum Surface {
        static let subtleFill = Color.primary.opacity(0.035)
        static let mutedFill = Color.secondary.opacity(0.09)
        static let elevatedFill = Color.primary.opacity(0.055)
        static let stroke = Color.secondary.opacity(0.18)
        static let tileStroke = Color.secondary.opacity(0.16)
        static let emphasisStroke = Color.primary.opacity(0.1)

        static var windowBackground: Color {
#if os(macOS)
            Color(nsColor: .windowBackgroundColor)
#else
            Color(uiColor: .systemGroupedBackground)
#endif
        }

        static var panelBackground: Color {
#if os(macOS)
            Color(nsColor: .controlBackgroundColor)
#else
            Color(uiColor: .secondarySystemGroupedBackground)
#endif
        }
    }
}