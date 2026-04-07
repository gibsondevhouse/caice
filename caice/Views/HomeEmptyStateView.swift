import SwiftUI

struct HomeEmptyStateView: View {
    let prompts: [String]
    let onPromptSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you want to build today?")
                    .font(AppTheme.Typography.heroTitle)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Use a starter or type your own prompt. Everything stays focused in chat.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            StarterPromptCardsView(prompts: prompts, onPromptSelected: onPromptSelected)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StarterPromptCardsView: View {
    let prompts: [String]
    let onPromptSelected: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 300), spacing: 12, alignment: .leading)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(prompts, id: \.self) { prompt in
                AppActionTile(isSelected: false, action: {
                    onPromptSelected(prompt)
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prompt)
                            .font(AppTheme.Typography.prominentBody)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        Text("Use prompt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
