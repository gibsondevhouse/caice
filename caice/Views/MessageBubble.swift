import SwiftUI

struct MessageBubble: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    private var textColor: Color {
        isUser ? .white : .primary
    }

    private var roleLabel: String {
        isUser ? "You" : "Caice"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isUser {
                Spacer(minLength: isCompactLayout ? 14 : 28)
            }

            if !isUser {
                circleAvatar
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(roleLabel)
                    .font(AppTheme.Typography.captionStrong)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.7)

                Text(message.text)
                    .font(AppTheme.Typography.bodyLeading)
                    .foregroundStyle(textColor)
                    .lineSpacing(2)
                    .padding(.horizontal, isCompactLayout ? 13 : 15)
                    .padding(.vertical, isCompactLayout ? 10 : 12)
                    .background(bubbleBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.bubble, style: .continuous)
                            .strokeBorder(bubbleStrokeColor, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.bubble, style: .continuous)
                            .strokeBorder(Color.white.opacity(isUser ? 0.18 : 0.14), lineWidth: 0.5)
                            .padding(1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.bubble, style: .continuous))
                    .shadow(color: shadowColor, radius: isUser ? 16 : 10, x: 0, y: isUser ? 9 : 6)
            }

            if isUser {
                circleAvatar
            }

            if !isUser {
                Spacer(minLength: isCompactLayout ? 14 : 28)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var bubbleBackground: some ShapeStyle {
        if isUser {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.95), Color.accentColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(AppTheme.Surface.bubbleAssistantGradient)
    }

    private var bubbleStrokeColor: Color {
        isUser ? Color.accentColor.opacity(0.28) : AppTheme.Surface.tileStroke
    }

    private var circleAvatar: some View {
        Circle()
            .fill(isUser ? Color.accentColor.opacity(0.18) : AppTheme.Surface.elevatedFill)
            .overlay(
                Circle()
                    .strokeBorder(isUser ? Color.accentColor.opacity(0.4) : AppTheme.Surface.emphasisStroke, lineWidth: 1)
            )
            .overlay {
                Image(systemName: isUser ? "person.fill" : "sparkles")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isUser ? Color.accentColor : .secondary)
            }
            .frame(width: 20, height: 20)
    }

    private var shadowColor: Color {
        isUser ? Color.accentColor.opacity(0.24) : Color.black.opacity(0.08)
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
}
