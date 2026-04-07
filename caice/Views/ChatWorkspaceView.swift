import SwiftUI

struct ChatWorkspaceView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
                titleFont: isCompactLayout ? .title2.weight(.semibold) : AppTheme.Typography.pageTitle,
                subtitleFont: .subheadline
            )
            .frame(maxWidth: AppTheme.Layout.chatContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, contentGutter)
            .padding(.top, isCompactLayout ? 20 : AppTheme.Layout.pageVerticalPadding)
            .padding(.bottom, 10)

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
            .padding(.horizontal, contentGutter)
            .padding(.top, 12)
            .padding(.bottom, isCompactLayout ? 14 : 22)
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
        .padding(.horizontal, contentGutter)
        .padding(.top, 10)
    }

    private var transcriptContent: some View {
        ScrollViewReader { proxy in
            AppCard(padding: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }
            }
            .frame(minHeight: isCompactLayout ? 240 : 320)
            .frame(maxWidth: AppTheme.Layout.chatContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, contentGutter)
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

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var contentGutter: CGFloat {
        isCompactLayout ? 16 : AppTheme.Layout.contentGutter
    }
}
