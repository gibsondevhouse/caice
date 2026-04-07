import SwiftUI

struct ChatComposerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var text: String
    let isSending: Bool
    let errorText: String?
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let errorText {
                AppErrorMessage(text: errorText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Compose")
                .font(AppTheme.Typography.captionStrong)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

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

                        Button {
                            onSend()
                        } label: {
                            if isSending {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Send", systemImage: "paperplane.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(isSending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    composerField

                    if isSending {
                        Button("Cancel") {
                            onCancel()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }

                    Button {
                        onSend()
                    } label: {
                        if isSending {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(isCompactLayout ? 18 : AppTheme.Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .strokeBorder(AppTheme.Surface.stroke, lineWidth: 1)
        )
        .shadow(
            color: AppTheme.Shadow.color,
            radius: AppTheme.Shadow.radius,
            x: AppTheme.Shadow.x,
            y: AppTheme.Shadow.y
        )
    }

    private var composerField: some View {
        TextField("Ask Caice anything", text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...8)
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                    .fill(AppTheme.Surface.elevatedFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                    .strokeBorder(AppTheme.Surface.emphasisStroke, lineWidth: 1)
            )
            .submitLabel(.send)
            .onSubmit {
                onSend()
            }
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
}
