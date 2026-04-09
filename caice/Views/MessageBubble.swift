import SwiftUI

struct MessageBubble: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isUser {
                Spacer(minLength: isCompactLayout ? 14 : 28)
            }

            if !isUser {
                circleAvatar
            }

            Text(message.text)
                .font(AppTheme.Typography.bodyLeading)
                .foregroundStyle(isUser ? Color.accentColor.opacity(0.94) : .primary)
                .lineSpacing(2)

            if isUser {
                circleAvatar
            }

            if !isUser {
                Spacer(minLength: isCompactLayout ? 14 : 28)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
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

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
}
