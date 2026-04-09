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
            workspaceHeader
            .frame(maxWidth: AppTheme.Layout.chatContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, contentGutter)
            .padding(.top, isCompactLayout ? 20 : AppTheme.Layout.pageVerticalPadding)
            .padding(.bottom, 14)

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
            .padding(.top, 14)
            .padding(.bottom, isCompactLayout ? 14 : 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.Surface.appBackdropGradient)
        .navigationTitle("")
        .toolbarTitleDisplayMode(.inline)
    }

    private var workspaceHeader: some View {
        VStack(alignment: .leading, spacing: 13) {
            AppPageHeader(
                title: "Chat",
                subtitle: "Local-first conversation workspace",
                titleFont: isCompactLayout ? .title2.weight(.semibold) : AppTheme.Typography.pageTitle,
                subtitleFont: .subheadline
            )

            HStack(spacing: 9) {
                headerPill(icon: "cpu", text: runtimeModelName)
                headerPill(icon: "bolt.fill", text: runtimeBadgeText)
            }
        }
        .padding(.vertical, 5)
    }

    private func headerPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(AppTheme.Surface.premiumPillGradient)
            )
            .overlay(
                Capsule()
                    .strokeBorder(AppTheme.Surface.tileStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HomeEmptyStateView(prompts: starterPrompts, onPromptSelected: onPromptSelected)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: AppTheme.Layout.chatContentWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.horizontal, contentGutter)
        .padding(.top, 8)
    }

    private var transcriptContent: some View {
        ScrollViewReader { proxy in
            AppCard(padding: 0) {
                ZStack {
                    AppTheme.Surface.transcriptGradient

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.14),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, AppTheme.Layout.transcriptPadding)
                        .padding(.vertical, AppTheme.Layout.transcriptPadding)
                    }
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
        isCompactLayout ? AppTheme.Layout.compactContentGutter : AppTheme.Layout.contentGutter
    }
}
