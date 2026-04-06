import SwiftUI

struct HomeEmptyStateView: View {
    let prompts: [String]
    let onPromptSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you want to work on?")
                    .font(.title.weight(.semibold))
                Text("Chat with your local model to brainstorm, debug, write, or plan your next move.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            StarterPromptChipsView(prompts: prompts, onPromptSelected: onPromptSelected)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct StarterPromptChipsView: View {
    let prompts: [String]
    let onPromptSelected: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 8, alignment: .leading)
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
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
