import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    private var bubbleColor: Color {
        isUser ? .accentColor : Color.secondary.opacity(0.18)
    }

    private var textColor: Color {
        isUser ? .white : .primary
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 32) }

            Text(message.text)
                .font(.body)
                .foregroundStyle(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(bubbleColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !isUser { Spacer(minLength: 32) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}
