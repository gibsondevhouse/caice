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

    static let maxComposerLines: Int = 10
    static let maxCharacterCount: Int = 4000

    @Binding var text: String
    let isSending: Bool
    let errorText: String?
    let onSend: () -> Void
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

    private func photoAction() {
        // Placeholder for a future attachment flow.
    }

    private func documentAction() {
        // Placeholder for a future attachment flow.
    }

    static func resolveControlState(trimmedText: String, isSending: Bool) -> ComposerControlState {
        if isSending {
            return .streaming
        }
        return trimmedText.isEmpty ? .idle : .composing
    }
}
