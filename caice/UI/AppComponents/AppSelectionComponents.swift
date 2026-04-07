import SwiftUI

struct AppActionTile<Content: View>: View {
    @State private var isHovering = false

    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Layout.tilePadding)
                .padding(.vertical, AppTheme.Layout.compactTilePadding)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.14) : (isHovering ? AppTheme.Surface.elevatedFill : AppTheme.Surface.subtleFill))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.45) : (isHovering ? AppTheme.Surface.emphasisStroke : AppTheme.Surface.tileStroke), lineWidth: 1)
                )
                .scaleEffect(isHovering ? 1.01 : 1)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous))
        .animation(.easeOut(duration: AppTheme.Motion.quick), value: isHovering)
#if os(macOS)
        .onHover { hovering in
            isHovering = hovering
        }
#endif
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
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sidebarTile, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sidebarTile, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.32) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
