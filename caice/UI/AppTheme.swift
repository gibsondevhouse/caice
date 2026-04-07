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
        static let sectionSpacing: CGFloat = 28
        static let cardPadding: CGFloat = 22
        static let tilePadding: CGFloat = 14
        static let chatContentWidth: CGFloat = 1020
        static let settingsContentWidth: CGFloat = 920
        static let pageHorizontalPadding: CGFloat = 32
        static let pageVerticalPadding: CGFloat = 28
    }

    enum CornerRadius {
        static let card: CGFloat = 22
        static let tile: CGFloat = 16
        static let compactTile: CGFloat = 14
        static let bubble: CGFloat = 14
    }

    enum Typography {
        static let pageTitle = Font.system(size: 34, weight: .semibold)
        static let heroTitle = Font.system(size: 46, weight: .semibold, design: .default)
        static let pageSubtitle = Font.title3.weight(.medium)
        static let sectionTitle = Font.title3.weight(.semibold)
        static let prominentBody = Font.body.weight(.medium)
    }

    enum Shadow {
        static let color = Color.black.opacity(0.05)
        static let radius: CGFloat = 14
        static let x: CGFloat = 0
        static let y: CGFloat = 5
    }

    enum Surface {
        static let subtleFill = Color.primary.opacity(0.035)
        static let mutedFill = Color.secondary.opacity(0.08)
        static let stroke = Color.secondary.opacity(0.16)
        static let tileStroke = Color.secondary.opacity(0.14)

        static var windowBackground: Color {
#if os(macOS)
            Color(nsColor: .windowBackgroundColor)
#else
            Color(uiColor: .systemGroupedBackground)
#endif
        }
    }
}