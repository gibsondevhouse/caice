import SwiftUI

struct ChatComposerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var text: String
    let isSending: Bool
    let errorText: String?
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            if let errorText {
                AppErrorMessage(text: errorText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .center, spacing: 10) {
                Label("Compose", systemImage: "pencil.line")
                    .font(AppTheme.Typography.captionStrong)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer(minLength: 0)

                if isSending {
                    Label("Streaming", systemImage: "waveform")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if isCompactLayout {
                VStack(alignment: .leading, spacing: 10) {
                    composerField

                    HStack(spacing: 8) {
                        if isSending {
                            Button("Cancel") {
                                onCancel()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }

                        Spacer(minLength: 0)

                        sendButton(controlSize: .regular, iconOnly: false)
                    }
                }
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    composerField

                    if isSending {
                        Button("Cancel") {
                            onCancel()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }

                    sendButton(controlSize: .large, iconOnly: false)
                }
            }
        }
        .padding(isCompactLayout ? 16 : 20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(AppTheme.Surface.panelGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .strokeBorder(AppTheme.Surface.stroke, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .strokeBorder(AppTheme.Surface.softOverlay, lineWidth: 0.5)
                .padding(1)
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .padding(1)
                .allowsHitTesting(false)
        }
        .shadow(
            color: AppTheme.Shadow.color,
            radius: AppTheme.Shadow.radius,
            x: AppTheme.Shadow.x,
            y: AppTheme.Shadow.y
        )
    }

    private func sendButton(controlSize: ControlSize, iconOnly: Bool) -> some View {
        Button {
            onSend()
        } label: {
            if isSending {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: iconOnly ? 34 : nil)
            } else {
                if iconOnly {
                    Label("Send", systemImage: "paperplane.fill")
                        .labelStyle(.iconOnly)
                } else {
                    Label("Send", systemImage: "paperplane.fill")
                        .labelStyle(.titleAndIcon)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, iconOnly ? 11 : 15)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.95),
                            Color.accentColor.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.24), lineWidth: 0.8)
        )
        .shadow(color: Color.accentColor.opacity(0.35), radius: 14, x: 0, y: 8)
        .foregroundStyle(.white)
        .controlSize(controlSize)
        .disabled(isSending || !canSend)
        .opacity(isSending || !canSend ? 0.55 : 1)
    }

    private var composerField: some View {
        TextField("Ask Caice anything", text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...8)
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                    .fill(AppTheme.Surface.composerFieldGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                    .strokeBorder(AppTheme.Surface.emphasisStroke, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                    .padding(1)
            }
            .submitLabel(.send)
            .onSubmit {
                onSend()
            }
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
