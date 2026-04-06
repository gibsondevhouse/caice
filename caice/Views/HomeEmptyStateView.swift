import SwiftUI

struct HomeEmptyStateView: View {
    let prompts: [String]
    let onPromptSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you want to work on?")
                    .font(.title2.weight(.semibold))
                Text("Start with a prompt and continue the conversation in one place.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            StarterPromptCardsView(prompts: prompts, onPromptSelected: onPromptSelected)
        }
        .frame(maxWidth: 680, alignment: .leading)
    }
}

private struct StarterPromptCardsView: View {
    let prompts: [String]
    let onPromptSelected: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 240), spacing: 10, alignment: .leading)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Try one")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(prompts, id: \.self) { prompt in
                    Button(prompt) {
                        onPromptSelected(prompt)
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
