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
        static let chatContentWidth: CGFloat = 880
        static let settingsContentWidth: CGFloat = 920
        static let pageHorizontalPadding: CGFloat = 34
        static let pageVerticalPadding: CGFloat = 32
        static let contentGutter: CGFloat = 34
        static let sidebarWidth: CGFloat = 280
        static let compactContentGutter: CGFloat = 16
        static let transcriptPadding: CGFloat = 18
    }

    enum CornerRadius {
        static let card: CGFloat = 22
        static let tile: CGFloat = 18
        static let compactTile: CGFloat = 14
        static let bubble: CGFloat = 18
        static let sidebarTile: CGFloat = 14
        static let pill: CGFloat = 999
    }

    enum Typography {
        static let pageTitle = Font.system(size: 35, weight: .semibold, design: .rounded)
        static let heroTitle = Font.system(size: 44, weight: .semibold, design: .rounded)
        static let pageSubtitle = Font.title3.weight(.medium)
        static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let prominentBody = Font.body.weight(.medium)
        static let bodyLeading = Font.body
        static let captionStrong = Font.caption.weight(.semibold)
        static let overline = Font.caption2.weight(.bold)
    }

    enum Shadow {
        static let color = Color.black.opacity(0.11)
        static let radius: CGFloat = 24
        static let x: CGFloat = 0
        static let y: CGFloat = 10
        static let ambient = Color.black.opacity(0.06)
        static let ambientRadius: CGFloat = 42
        static let ambientY: CGFloat = 24
    }

    enum Motion {
        static let quick: Double = 0.16
        static let regular: Double = 0.24
    }

    enum Surface {
        static let warmGlow = Color(red: 0.96, green: 0.79, blue: 0.56)
        static let coolGlow = Color(red: 0.55, green: 0.69, blue: 0.86)
        static let subtleFill = Color.primary.opacity(0.04)
        static let mutedFill = Color.secondary.opacity(0.09)
        static let elevatedFill = Color.primary.opacity(0.065)
        static let stroke = Color.secondary.opacity(0.24)
        static let tileStroke = Color.secondary.opacity(0.2)
        static let emphasisStroke = Color.primary.opacity(0.14)
        static let strongStroke = Color.primary.opacity(0.18)
        static let softOverlay = Color.white.opacity(0.22)

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

        static var appBackdropGradient: LinearGradient {
            LinearGradient(
                colors: [
                    windowBackground.opacity(0.98),
                    panelBackground.opacity(0.93),
                    windowBackground.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var sidebarGradient: LinearGradient {
            LinearGradient(
                colors: [
                    panelBackground.opacity(0.9),
                    windowBackground.opacity(0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var panelGradient: LinearGradient {
            LinearGradient(
                colors: [
                    panelBackground.opacity(0.78),
                    windowBackground.opacity(0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var transcriptGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.038),
                    Color.primary.opacity(0.014)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var bubbleAssistantGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.092),
                    Color.primary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var composerFieldGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.09),
                    Color.primary.opacity(0.045)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var premiumPillGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.white.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        static var promptCardGradient: LinearGradient {
            LinearGradient(
                colors: [
                    elevatedFill.opacity(1.1),
                    subtleFill.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}