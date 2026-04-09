import SwiftUI

struct AppActionTile<Content: View>: View {
    @State private var isHovering = false
    @State private var isPressed = false

    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Layout.tilePadding)
                .padding(.vertical, AppTheme.Layout.tilePadding)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                        .fill(tileFillStyle)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                        .strokeBorder(
                            isSelected
                                ? Color.accentColor.opacity(0.48)
                                : (isHovering ? AppTheme.Surface.emphasisStroke : AppTheme.Surface.tileStroke),
                            lineWidth: 1
                        )
                )
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous)
                        .strokeBorder(AppTheme.Surface.softOverlay, lineWidth: 0.5)
                        .padding(1)
                }
                .shadow(color: Color.black.opacity(isHovering ? 0.08 : 0.04), radius: isHovering ? 12 : 8, x: 0, y: isHovering ? 8 : 4)
                .scaleEffect(isPressed ? 0.994 : (isHovering ? 1.01 : 1))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.tile, style: .continuous))
        .animation(.easeOut(duration: AppTheme.Motion.quick), value: isHovering)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
#if os(macOS)
        .onHover { hovering in
            isHovering = hovering
        }
#endif
    }

    private var tileFillStyle: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor.opacity(0.17))
        }
        if isHovering {
            return AnyShapeStyle(AppTheme.Surface.promptCardGradient)
        }
        return AnyShapeStyle(AppTheme.Surface.subtleFill)
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
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 16)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sidebarTile, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : AppTheme.Surface.elevatedFill.opacity(0.001))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sidebarTile, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.34) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
