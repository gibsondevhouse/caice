import SwiftUI

struct AppStatusBadge: View {
    let title: String
    let color: Color
    let systemImage: String

    init(title: String, color: Color, systemImage: String) {
        self.title = title
        self.color = color
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.14))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(color.opacity(0.24), lineWidth: 1)
        )
    }
}

struct AppAlertBadge: View {
    let text: String
    let accent: Color
    let systemImage: String

    init(text: String, accent: Color = AppTheme.Accent.warning, systemImage: String = "exclamationmark.triangle.fill") {
        self.text = text
        self.accent = accent
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(accent.opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(accent.opacity(0.22), lineWidth: 1)
        )
    }
}
