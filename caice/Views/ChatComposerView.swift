import SwiftUI

enum ComposerControlState: Equatable {
    case idle
    case composing
    case streaming

    var sendEnabled: Bool {
        self == .composing
    }

    var stopEnabled: Bool {
        self == .streaming
    }
}

enum ComposerMode: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case agent = "Agent"
    case research = "Research"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .chat:
            return "bubble.left.and.bubble.right"
        case .agent:
            return "sparkles"
        case .research:
            return "magnifyingglass"
        }
    }
}

struct ChatComposerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var isComposerFocused: Bool
    @State private var selectedMode: ComposerMode = .chat
    @State private var activeOverlay: ComposerOverlay?

    static let maxComposerLines: Int = 10
    static let maxCharacterCount: Int = 4000

    @Binding var text: String
    let showsModeSuggestions: Bool
    let isSending: Bool
    let errorText: String?
    let onSend: () -> Void
    let onSuggestionAction: (String, String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let errorText {
                AppErrorMessage(text: errorText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            composerField

            HStack(alignment: .center, spacing: 12) {
                leadingActionPill

                Spacer(minLength: 0)

                modeControls

                Spacer(minLength: 0)

                sendStopPill
            }
            .frame(height: AppSplitPill.height)

            if shouldShowModeSuggestions {
                modeSuggestionChips
            }

            Text("Cmd+Return to send")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            if text.isEmpty {
                isComposerFocused = true
            }
        }
        .onChange(of: selectedMode) {
            activeOverlay = nil
        }
        .onChange(of: trimmedText) { _, updatedText in
            if !updatedText.isEmpty {
                activeOverlay = nil
            }
        }
    }

    private var modeSuggestionChips: some View {
        HStack(spacing: 8) {
            ForEach(modeSuggestions) { suggestion in
                suggestionChip(suggestion)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .overlay(alignment: .top) {
            if let activeOverlay {
                centeredSuggestionOverlay(activeOverlay)
            }
        }
        .zIndex(2)
    }

    private func centeredSuggestionOverlay(_ overlay: ComposerOverlay) -> some View {
        GeometryReader { proxy in
            suggestionOverlay(overlay)
                .frame(width: max(220, proxy.size.width * 0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .offset(y: 42)
        }
        .frame(height: 260)
    }

    private func suggestionChip(_ suggestion: ComposerSuggestion) -> some View {
        Button {
            handleSuggestionTap(suggestion)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: suggestion.iconName)
                    .font(.caption2.weight(.semibold))

                Text(suggestion.title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(minWidth: 86, alignment: .center)
                .background(
                    Capsule()
                        .fill(AppTheme.Surface.premiumPillGradient)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(AppTheme.Surface.tileStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func suggestionOverlay(_ overlay: ComposerOverlay) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Label(overlayTitle(for: overlay), systemImage: overlayIconName(for: overlay))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        activeOverlay = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .overlay(AppTheme.Surface.tileStroke)
                .padding(.horizontal, 14)

            Text(overlaySubtitle(for: overlay))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Divider()
                .overlay(AppTheme.Surface.tileStroke)
                .padding(.horizontal, 14)

            let options = overlayOptions(for: overlay)
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                Button {
                    triggerSuggestionAction(option)
                } label: {
                    Label(option.title, systemImage: option.iconName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if index < options.count - 1 {
                    Divider()
                        .overlay(AppTheme.Surface.tileStroke)
                        .padding(.horizontal, 14)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.Surface.panelBackground.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppTheme.Surface.tileStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
    }

    private var composerField: some View {
        TextField("Ask Caice anything", text: $text, axis: .vertical)
            .focused($isComposerFocused)
            .textFieldStyle(.plain)
            .font(.body)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .lineLimit(1...ChatComposerView.maxComposerLines)
            .onChange(of: text) { _, updatedText in
                if updatedText.count > ChatComposerView.maxCharacterCount {
                    text = String(updatedText.prefix(ChatComposerView.maxCharacterCount))
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                    .fill(AppTheme.Surface.liquidGlassDarkTint)
            )
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                    .fill(AppTheme.Surface.liquidGlassComposerGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                    .strokeBorder(
                        isComposerFocused ? Color.accentColor.opacity(0.62) : AppTheme.Surface.liquidGlassStroke,
                        lineWidth: isComposerFocused ? 1.2 : 1
                    )
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                    .strokeBorder(AppTheme.Surface.liquidGlassHighlight.opacity(0.6), lineWidth: 0.5)
                    .padding(1)
            }
            .onTapGesture {
                isComposerFocused = true
            }
            .accessibilityHint("Press Command Return to send")
    }

    private var leadingActionPill: some View {
        AppSplitPill(
            leading: .init(
                title: "Photo",
                systemImage: "photo",
                iconOnly: true,
                isEnabled: false,
                isEmphasized: false,
                action: photoAction
            ),
            trailing: .init(
                title: "Document",
                systemImage: "doc",
                iconOnly: true,
                isEnabled: false,
                isEmphasized: false,
                action: documentAction
            )
        )
        .frame(width: 84)
        .accessibilityLabel("Attachment actions")
    }

    private var modeControls: some View {
        AppTriPillControl(
            segments: ComposerMode.allCases.map {
                AppTriPillControl.Segment(id: $0.id, systemImage: $0.iconName)
            },
            selectedID: selectedMode.id,
            onSelect: { selectedID in
                guard let mode = ComposerMode.allCases.first(where: { $0.id == selectedID }) else {
                    return
                }
                selectedMode = mode
            }
        )
        .frame(width: 126)
        .accessibilityLabel("Chat mode")
    }

    private var sendStopPill: some View {
        AppSplitPill(
            leading: .init(
                title: "Stop",
                systemImage: "stop.fill",
                iconOnly: true,
                isEnabled: controlState.stopEnabled,
                isEmphasized: controlState.stopEnabled,
                action: onCancel
            ),
            trailing: .init(
                title: "Send",
                systemImage: "paperplane.fill",
                iconOnly: true,
                isEnabled: controlState.sendEnabled,
                isEmphasized: controlState.sendEnabled,
                keyboardShortcut: KeyboardShortcut(.return, modifiers: [.command]),
                action: onSend
            )
        )
        .frame(width: 84)
        .disabled(!controlState.sendEnabled && !controlState.stopEnabled)
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var controlState: ComposerControlState {
        ChatComposerView.resolveControlState(trimmedText: trimmedText, isSending: isSending)
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var modeSuggestions: [ComposerSuggestion] {
        switch selectedMode {
        case .chat:
            return [.write, .discuss, .news]
        case .agent, .research:
            return []
        }
    }

    private var shouldShowModeSuggestions: Bool {
        showsModeSuggestions && trimmedText.isEmpty && !modeSuggestions.isEmpty
    }

    private func photoAction() {
        // Placeholder for a future attachment flow.
    }

    private func documentAction() {
        // Placeholder for a future attachment flow.
    }

    private func handleSuggestionTap(_ suggestion: ComposerSuggestion) {
        switch suggestion {
        case .write:
            toggleOverlay(.writeCoAuthoring)
        case .discuss:
            toggleOverlay(.discussPlanning)
        case .news:
            toggleOverlay(.newsBriefing)
        }
    }

    private func toggleOverlay(_ overlay: ComposerOverlay) {
        withAnimation(.easeInOut(duration: 0.18)) {
            activeOverlay = activeOverlay == overlay ? nil : overlay
        }
    }

    private func triggerSuggestionAction(_ option: SuggestionOverlayOption) {
        onSuggestionAction(option.userMessageText, option.actionPrompt)
        withAnimation(.easeInOut(duration: 0.16)) {
            activeOverlay = nil
        }
    }

    private func overlayTitle(for overlay: ComposerOverlay) -> String {
        switch overlay {
        case .writeCoAuthoring:
            return "Co-authoring"
        case .discussPlanning:
            return "Discussion Planner"
        case .newsBriefing:
            return "News Briefing"
        }
    }

    private func overlaySubtitle(for overlay: ComposerOverlay) -> String {
        switch overlay {
        case .writeCoAuthoring:
            return "Choose a format"
        case .discussPlanning:
            return "Choose a discussion workflow"
        case .newsBriefing:
            return "Choose a news workflow"
        }
    }

    private func overlayIconName(for overlay: ComposerOverlay) -> String {
        switch overlay {
        case .writeCoAuthoring:
            return "square.and.pencil"
        case .discussPlanning:
            return "bubble.left.and.bubble.right"
        case .newsBriefing:
            return "newspaper"
        }
    }

    private func overlayOptions(for overlay: ComposerOverlay) -> [SuggestionOverlayOption] {
        switch overlay {
        case .writeCoAuthoring:
            return CoAuthorOption.allCases.map {
                SuggestionOverlayOption(
                    id: $0.id,
                    title: $0.title,
                    iconName: $0.iconName,
                    userMessageText: $0.userMessageText,
                    actionPrompt: $0.actionPrompt
                )
            }
        case .discussPlanning:
            return DiscussOption.allCases.map {
                SuggestionOverlayOption(
                    id: $0.id,
                    title: $0.title,
                    iconName: $0.iconName,
                    userMessageText: $0.userMessageText,
                    actionPrompt: $0.actionPrompt
                )
            }
        case .newsBriefing:
            return NewsOption.allCases.map {
                SuggestionOverlayOption(
                    id: $0.id,
                    title: $0.title,
                    iconName: $0.iconName,
                    userMessageText: $0.userMessageText,
                    actionPrompt: $0.actionPrompt
                )
            }
        }
    }

    static func resolveControlState(trimmedText: String, isSending: Bool) -> ComposerControlState {
        if isSending {
            return .streaming
        }
        return trimmedText.isEmpty ? .idle : .composing
    }
}

private enum ComposerSuggestion: String, CaseIterable, Identifiable {
    case write
    case discuss
    case news

    var id: String { rawValue }

    var title: String {
        switch self {
        case .write:
            return "Write"
        case .discuss:
            return "Discuss"
        case .news:
            return "News"
        }
    }

    var iconName: String {
        switch self {
        case .write:
            return "square.and.pencil"
        case .discuss:
            return "bubble.left.and.bubble.right"
        case .news:
            return "newspaper"
        }
    }
}

private enum ComposerOverlay: Equatable {
    case writeCoAuthoring
    case discussPlanning
    case newsBriefing
}

private struct SuggestionOverlayOption: Identifiable {
    let id: String
    let title: String
    let iconName: String
    let userMessageText: String
    let actionPrompt: String
}

private enum CoAuthorOption: String, CaseIterable, Identifiable {
    case articles
    case podcastScripts
    case shortStories
    case journalEntries

    var id: String { rawValue }

    var title: String {
        switch self {
        case .articles:
            return "Articles"
        case .podcastScripts:
            return "Podcast Scripts"
        case .shortStories:
            return "Short Stories"
        case .journalEntries:
            return "Journal Entries"
        }
    }

    var iconName: String {
        switch self {
        case .articles:
            return "doc.text"
        case .podcastScripts:
            return "mic"
        case .shortStories:
            return "book.closed"
        case .journalEntries:
            return "calendar"
        }
    }

    var actionPrompt: String {
        switch self {
        case .articles:
            return "The user selected co-authoring for an article. Ask exactly one concise kickoff question to plan the piece. Ask only the question. Example style: What is this article about?"
        case .podcastScripts:
            return "The user selected co-authoring for a podcast script. Ask exactly one concise kickoff question to plan it. Ask only the question. Example style: Who is the main audience for the podcast?"
        case .shortStories:
            return "The user selected co-authoring for a short story. Ask exactly one concise kickoff question to start drafting. Ask only the question. Example style: What genre and tone should this short story have?"
        case .journalEntries:
            return "The user selected co-authoring for a journal entry. Ask exactly one concise kickoff question to guide the entry. Ask only the question. Example style: What moment or feeling should this journal entry focus on?"
        }
    }

    var userMessageText: String {
        switch self {
        case .articles:
            return "Let's co-author an article."
        case .podcastScripts:
            return "Let's co-author a podcast script."
        case .shortStories:
            return "Let's co-author a short story."
        case .journalEntries:
            return "Let's co-author a journal entry."
        }
    }
}

private enum DiscussOption: String, CaseIterable, Identifiable {
    case planning
    case decision
    case feedback
    case interviewPrep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planning:
            return "Planning Session"
        case .decision:
            return "Decision Review"
        case .feedback:
            return "Feedback Synthesis"
        case .interviewPrep:
            return "Interview Prep"
        }
    }

    var iconName: String {
        switch self {
        case .planning:
            return "list.bullet.clipboard"
        case .decision:
            return "checklist"
        case .feedback:
            return "text.bubble"
        case .interviewPrep:
            return "person.badge.questionmark"
        }
    }

    var actionPrompt: String {
        switch self {
        case .planning:
            return "The user selected a discussion planning session. Ask exactly one concise kickoff question to scope the discussion. Ask only the question."
        case .decision:
            return "The user selected decision review. Ask exactly one concise kickoff question to frame trade-offs and criteria. Ask only the question."
        case .feedback:
            return "The user selected feedback synthesis. Ask exactly one concise kickoff question to identify sources and desired outcome. Ask only the question."
        case .interviewPrep:
            return "The user selected interview prep. Ask exactly one concise kickoff question about role, level, or focus area. Ask only the question."
        }
    }

    var userMessageText: String {
        switch self {
        case .planning:
            return "Let's plan a discussion session."
        case .decision:
            return "Let's run a decision review."
        case .feedback:
            return "Let's synthesize feedback."
        case .interviewPrep:
            return "Let's prepare for an interview."
        }
    }
}

private enum NewsOption: String, CaseIterable, Identifiable {
    case dailyBrief
    case industryScan
    case competitorWatch
    case policyUpdates

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dailyBrief:
            return "Daily Brief"
        case .industryScan:
            return "Industry Scan"
        case .competitorWatch:
            return "Competitor Watch"
        case .policyUpdates:
            return "Policy Updates"
        }
    }

    var iconName: String {
        switch self {
        case .dailyBrief:
            return "sun.max"
        case .industryScan:
            return "building.2"
        case .competitorWatch:
            return "eye"
        case .policyUpdates:
            return "building.columns"
        }
    }

    var actionPrompt: String {
        switch self {
        case .dailyBrief:
            return "The user selected a daily news brief. Ask exactly one concise kickoff question about topics, region, and timeframe. Ask only the question."
        case .industryScan:
            return "The user selected an industry scan. Ask exactly one concise kickoff question about industry, depth, and target audience. Ask only the question."
        case .competitorWatch:
            return "The user selected competitor watch. Ask exactly one concise kickoff question about companies and signals to monitor. Ask only the question."
        case .policyUpdates:
            return "The user selected policy updates. Ask exactly one concise kickoff question about jurisdiction and policy domain. Ask only the question."
        }
    }

    var userMessageText: String {
        switch self {
        case .dailyBrief:
            return "Give me a daily news brief."
        case .industryScan:
            return "Run an industry news scan."
        case .competitorWatch:
            return "Start a competitor watch update."
        case .policyUpdates:
            return "Give me policy updates."
        }
    }
}
