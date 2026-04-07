import SwiftUI

struct HomeEmptyStateView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let prompts: [String]
    let onPromptSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isCompactLayout ? 16 : 22) {
            VStack(alignment: .leading, spacing: isCompactLayout ? 8 : 10) {
                Text("What do you want to build today?")
                    .font(isCompactLayout ? .title.weight(.semibold) : AppTheme.Typography.heroTitle)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Use a starter or type your own prompt. Everything stays focused in chat.")
                    .font(.title3.weight(.regular))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }

            StarterPromptCardsView(prompts: prompts, onPromptSelected: onPromptSelected)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
}

private struct StarterPromptCardsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let prompts: [String]
    let onPromptSelected: (String) -> Void

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: isCompactLayout ? 220 : 300), spacing: 12, alignment: .leading)
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(prompts, id: \.self) { prompt in
                AppActionTile(isSelected: false, action: {
                    onPromptSelected(prompt)
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(prompt)
                            .font(AppTheme.Typography.prominentBody)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .lineSpacing(1)

                        Text("Use prompt")
                            .font(AppTheme.Typography.captionStrong)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
}
