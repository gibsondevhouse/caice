import SwiftUI

struct ChatWorkspaceView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var centeredComposerHeight: CGFloat = 160

    let conversationTitle: String
    let runtimeModelName: String
    let runtimeBadgeText: String
    let availableModelNames: [String]
    let starterPrompts: [String]
    let messages: [ChatMessage]
    let streamingRevision: Int
    @Binding var composerText: String
    let isSending: Bool
    let errorText: String?
    let onPromptSelected: (String) -> Void
    let onSelectModel: (String) -> Void
    let onSend: () -> Void
    let onSuggestionAction: (String, String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            workspaceHeader

            if showsCenteredComposerLayout {
                centeredComposerContent
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .move(edge: .top))
                        )
                    )
            } else {
                activeTranscriptLayout
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        )
                    )
            }
        }
        .animation(.easeInOut(duration: 0.24), value: showsCenteredComposerLayout)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.Surface.appBackdropGradient)
        .navigationTitle("")
        .toolbarTitleDisplayMode(.inline)
    }

    private var workspaceHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppPageHeader(
                title: conversationTitle,
                subtitle: nil,
                titleFont: isCompactLayout ? .title3.weight(.semibold) : .title2.weight(.semibold),
                subtitleFont: .subheadline
            )

            HStack(spacing: 9) {
                modelSelectorControl
                headerPill(icon: "bolt.fill", text: runtimeBadgeText)
            }
        }
        .frame(maxWidth: AppTheme.Layout.chatContentWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, contentGutter)
        .padding(.top, isCompactLayout ? 10 : 14)
        .padding(.bottom, 8)
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

    @ViewBuilder
    private var modelSelectorControl: some View {
        if availableModelNames.isEmpty {
            modelPillLabel
                .opacity(0.65)
        } else {
            Menu {
                ForEach(availableModelNames, id: \.self) { name in
                    Button(name) { onSelectModel(name) }
                }
            } label: {
                modelPillLabel
            }
#if os(macOS)
            .menuStyle(.borderlessButton)
#endif
            .fixedSize()
        }
    }

    private var modelPillLabel: some View {
        Label(runtimeModelName, systemImage: "cpu")
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

    private var centeredComposerContent: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()

            VStack(alignment: .center, spacing: 12) {
                Text("Welcome to C.A.I.C.E")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Cognitive Assistant for Inquiry, Coordination, and Execution")
                    .font(.subheadline.weight(.regular))
                    .foregroundStyle(.secondary)

                Spacer()
                    .frame(height: 20)

                composerSection
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var activeTranscriptLayout: some View {
        ZStack(alignment: .bottom) {
            transcriptContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            composerSection
                .padding(.bottom, isCompactLayout ? 6 : 10)
        }
    }

    private var starterSuggestions: some View {
        HomeEmptyStateView(prompts: starterPrompts, onPromptSelected: onPromptSelected)
            .frame(maxWidth: AppTheme.Layout.chatContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, contentGutter)
    }

    private var composerSection: some View {
        ChatComposerView(
            text: $composerText,
            showsModeSuggestions: showsCenteredComposerLayout,
            isSending: isSending,
            errorText: errorText,
            onSend: onSend,
            onSuggestionAction: onSuggestionAction,
            onCancel: onCancel
        )
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ComposerHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(ComposerHeightPreferenceKey.self) { measuredHeight in
            if measuredHeight > 0 {
                centeredComposerHeight = measuredHeight
            }
        }
        .frame(maxWidth: AppTheme.Layout.chatContentWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, contentGutter)
        .padding(.top, 14)
        .padding(.bottom, isCompactLayout ? 14 : 22)
    }

    private var transcriptContent: some View {
        ScrollViewReader { proxy in
            ZStack {
                AppTheme.Surface.transcriptGradient

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            MessageBubble(message: message)
                                .id(message.id)
                                .padding(.bottom, spacingAfterMessage(at: index))
                        }
                    }
                    .frame(maxWidth: AppTheme.Layout.chatContentWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AppTheme.Layout.transcriptPadding)
                    .padding(.vertical, AppTheme.Layout.transcriptPadding)
                    .padding(.bottom, composerOverlayInset)
                }
            }
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.05),
                        .init(color: .black, location: 0.95),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(minHeight: isCompactLayout ? 240 : 320)
            .frame(maxWidth: .infinity)
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

    private var showsCenteredComposerLayout: Bool {
        messages.isEmpty && !isSending
    }

    private var contentGutter: CGFloat {
        isCompactLayout ? AppTheme.Layout.compactContentGutter : AppTheme.Layout.contentGutter
    }

    private var composerOverlayInset: CGFloat {
        centeredComposerHeight + (isCompactLayout ? 34 : 42)
    }

    private func spacingAfterMessage(at index: Int) -> CGFloat {
        guard index + 1 < messages.count else { return 0 }
        return messages[index].role != messages[index + 1].role ? 24 : 10
    }
}

private struct ComposerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
