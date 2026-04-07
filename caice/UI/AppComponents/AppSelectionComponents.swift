import SwiftUI

struct AppActionTile<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Layout.tilePadding)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.12) : AppTheme.Surface.subtleFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.45) : AppTheme.Surface.tileStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct AppSidebarRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
