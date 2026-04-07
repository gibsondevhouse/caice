import SwiftUI

struct ChatComposerView: View {
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

            Text("Message")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask Caice anything", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...8)
                    .font(.title3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                            .fill(AppTheme.Surface.subtleFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                            .strokeBorder(AppTheme.Surface.tileStroke, lineWidth: 1)
                    )
                    .submitLabel(.send)
                    .onSubmit {
                        onSend()
                    }

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
        .padding(AppTheme.Layout.cardPadding)
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
}
