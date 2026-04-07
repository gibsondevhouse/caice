import SwiftUI

struct MessageBubble: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    private var bubbleColor: Color {
        isUser ? .accentColor : AppTheme.Surface.subtleFill
    }

    private var textColor: Color {
        isUser ? .white : .primary
    }

    private var roleLabel: String {
        isUser ? "You" : "Caice"
    }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            Text(roleLabel)
                .font(AppTheme.Typography.captionStrong)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.7)

            HStack {
                if isUser { Spacer(minLength: isCompactLayout ? 16 : 32) }

                Text(message.text)
                    .font(AppTheme.Typography.bodyLeading)
                    .foregroundStyle(textColor)
                    .lineSpacing(2)
                    .padding(.horizontal, isCompactLayout ? 12 : 14)
                    .padding(.vertical, isCompactLayout ? 10 : 11)
                    .background(bubbleColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.bubble, style: .continuous)
                            .strokeBorder(
                                isUser ? Color.accentColor.opacity(0.2) : AppTheme.Surface.tileStroke,
                                lineWidth: 1
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.bubble, style: .continuous))

                if !isUser { Spacer(minLength: isCompactLayout ? 16 : 32) }
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
}
