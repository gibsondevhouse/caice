import SwiftUI

struct ChatWorkspaceView: View {
    let runtimeModelName: String
    let runtimeBadgeText: String
    let starterPrompts: [String]
    let messages: [ChatMessage]
    let streamingRevision: Int
    @Binding var composerText: String
    let isSending: Bool
    let errorText: String?
    let onPromptSelected: (String) -> Void
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AppPageHeader(
                title: "Chat",
                subtitle: "Local | \(runtimeModelName) | \(runtimeBadgeText)",
                titleFont: .largeTitle.weight(.semibold),
                subtitleFont: .subheadline
            )
            .frame(maxWidth: AppTheme.Layout.chatContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 36)
            .padding(.top, 30)
            .padding(.bottom, 8)

            if messages.isEmpty {
                emptyContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                transcriptContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            ChatComposerView(
                text: $composerText,
                isSending: isSending,
                errorText: errorText,
                onSend: onSend,
                onCancel: onCancel
            )
            .frame(maxWidth: AppTheme.Layout.chatContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 36)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("")
        .toolbarTitleDisplayMode(.inline)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HomeEmptyStateView(prompts: starterPrompts, onPromptSelected: onPromptSelected)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: AppTheme.Layout.chatContentWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.horizontal, 36)
        .padding(.top, 8)
    }

    private var transcriptContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 16)
            }
            .frame(maxWidth: AppTheme.Layout.chatContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .onChange(of: messages.count) {
                scrollToLatest(proxy)
            }
            .onChange(of: streamingRevision) {
                scrollToLatest(proxy)
            }
        }
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        guard let lastID = messages.last?.id else {
            return
        }

        withAnimation {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}
