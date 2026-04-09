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

struct AppSplitPill: View {
    static let height: CGFloat = 36

    struct Segment {
        let title: String
        let systemImage: String
        let iconOnly: Bool
        let isEnabled: Bool
        let isEmphasized: Bool
        let keyboardShortcut: KeyboardShortcut?
        let action: () -> Void

        init(
            title: String,
            systemImage: String,
            iconOnly: Bool = false,
            isEnabled: Bool,
            isEmphasized: Bool,
            keyboardShortcut: KeyboardShortcut? = nil,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.systemImage = systemImage
            self.iconOnly = iconOnly
            self.isEnabled = isEnabled
            self.isEmphasized = isEmphasized
            self.keyboardShortcut = keyboardShortcut
            self.action = action
        }
    }

    let leading: Segment
    let trailing: Segment

    var body: some View {
        HStack(spacing: 0) {
            segmentButton(for: leading)

            Rectangle()
                .fill(AppTheme.Surface.liquidGlassStroke.opacity(0.9))
                .frame(width: 1)
                .padding(.vertical, 6)

            segmentButton(for: trailing)
        }
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.Surface.liquidGlassDarkTint)
        )
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.Surface.liquidGlassComposerGradient)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(AppTheme.Surface.liquidGlassStroke, lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            Capsule(style: .continuous)
                .strokeBorder(AppTheme.Surface.liquidGlassHighlight.opacity(0.65), lineWidth: 0.5)
                .padding(1)
        }
        .frame(height: Self.height)
        .clipShape(Capsule(style: .continuous))
    }

    private func segmentButton(for segment: Segment) -> some View {
        Button(action: segment.action) {
            Group {
                if segment.iconOnly {
                    Image(systemName: segment.systemImage)
                } else {
                    Label(segment.title, systemImage: segment.systemImage)
                        .labelStyle(.titleAndIcon)
                        .frame(minWidth: 72)
                        .padding(.horizontal, 11)
                }
            }
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(foregroundColor(for: segment))
            .background(segmentBackground(for: segment))
        }
        .buttonStyle(.plain)
        .modifier(OptionalKeyboardShortcutModifier(shortcut: segment.keyboardShortcut))
        .disabled(!segment.isEnabled)
        .opacity(segment.isEnabled || segment.isEmphasized ? 1 : 0.92)
    }

    private func foregroundColor(for segment: Segment) -> Color {
        if segment.isEnabled && segment.isEmphasized {
            return .white
        }
        return AppTheme.Surface.splitPillDisabledForeground
    }

    @ViewBuilder
    private func segmentBackground(for segment: Segment) -> some View {
        Group {
            if segment.isEnabled && segment.isEmphasized {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.95),
                                Color.accentColor.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                Rectangle()
                    .fill(AppTheme.Surface.splitPillDisabledFill)
            }
        }
    }
}

private struct OptionalKeyboardShortcutModifier: ViewModifier {
    let shortcut: KeyboardShortcut?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let shortcut {
            content.keyboardShortcut(shortcut)
        } else {
            content
        }
    }
}

struct AppSinglePillControl: View {
    static let height: CGFloat = 30

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(height: Self.height)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(selectedGradient) : AnyShapeStyle(AppTheme.Surface.liquidGlassComposerGradient))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.4) : AppTheme.Surface.liquidGlassStroke, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    Capsule(style: .continuous)
                        .strokeBorder(AppTheme.Surface.liquidGlassHighlight.opacity(0.55), lineWidth: 0.5)
                        .padding(1)
                }
        }
        .buttonStyle(.plain)
    }

    private var selectedGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.95),
                Color.accentColor.opacity(0.76)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AppTriPillControl: View {
    struct Segment: Identifiable {
        let id: String
        let systemImage: String
    }

    let segments: [Segment]
    let selectedID: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                Button {
                    onSelect(segment.id)
                } label: {
                    Image(systemName: segment.systemImage)
                        .font(.caption.weight(.semibold))
                        .frame(minWidth: 34)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(selectedID == segment.id ? Color.white : .secondary)
                        .background(
                            Group {
                                if selectedID == segment.id {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.accentColor.opacity(0.95),
                                                    Color.accentColor.opacity(0.76)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)

                if index < segments.count - 1 {
                    Rectangle()
                        .fill(AppTheme.Surface.liquidGlassStroke.opacity(0.9))
                        .frame(width: 1)
                        .padding(.vertical, 6)
                }
            }
        }
        .frame(height: AppSplitPill.height)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.Surface.liquidGlassDarkTint)
        )
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.Surface.liquidGlassComposerGradient)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(AppTheme.Surface.liquidGlassStroke, lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            Capsule(style: .continuous)
                .strokeBorder(AppTheme.Surface.liquidGlassHighlight.opacity(0.55), lineWidth: 0.5)
                .padding(1)
        }
        .clipShape(Capsule(style: .continuous))
    }
}

