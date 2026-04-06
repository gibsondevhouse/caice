import SwiftUI

struct ChatComposerView: View {
    @Binding var text: String
    let isSending: Bool
    let errorText: String?
    let modelName: String
    let statusText: String
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Label(modelName, systemImage: "cpu")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(statusText, systemImage: isSending ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(isSending ? .blue : .secondary)
            }

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask Caice anything", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
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
                .disabled(isSending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}
