import SwiftUI

struct HomeEmptyStateView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let prompts: [String]
    let onPromptSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isCompactLayout ? 18 : 24) {
            VStack(alignment: .leading, spacing: isCompactLayout ? 10 : 12) {
                Text("Start a conversation")
                    .font(AppTheme.Typography.overline)
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(.secondary)

                Text("What do you want to build today?")
                    .font(isCompactLayout ? .title.weight(.semibold) : AppTheme.Typography.heroTitle)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Choose a starter or compose your own prompt. Keep momentum high while every conversation stays local.")
                    .font(.title3.weight(.regular))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .frame(maxWidth: 720, alignment: .leading)
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
            GridItem(.adaptive(minimum: isCompactLayout ? 220 : 290), spacing: 12, alignment: .leading)
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(prompts, id: \.self) { prompt in
                AppActionTile(isSelected: false, action: {
                    onPromptSelected(prompt)
                }) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.accentColor)

                            Text("Starter")
                                .font(AppTheme.Typography.overline)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.8)

                            Circle()
                                .fill(Color.secondary.opacity(0.5))
                                .frame(width: 3, height: 3)

                            Text("Quick launch")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Spacer(minLength: 0)

                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(prompt)
                            .font(AppTheme.Typography.prominentBody)
                            .multilineTextAlignment(.leading)
                            .lineLimit(4)
                            .lineSpacing(1.5)

                        Text("Use this prompt")
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
