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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(color.opacity(0.22), lineWidth: 1)
        )
    }
}

struct AppInlineNotice: View {
    let text: String
    let tint: Color
    let systemImage: String

    init(text: String, tint: Color, systemImage: String) {
        self.text = text
        self.tint = tint
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .padding(.top, 2)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppTheme.Layout.tilePadding)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .fill(tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .strokeBorder(tint.opacity(0.16), lineWidth: 1)
        )
    }
}

struct AppSuccessMessage: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.Accent.success)
                .padding(.top, 2)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppTheme.Layout.tilePadding)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .fill(AppTheme.Accent.success.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .strokeBorder(AppTheme.Accent.success.opacity(0.16), lineWidth: 1)
        )
    }
}

struct AppErrorMessage: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(AppTheme.Accent.critical)
                .padding(.top, 2)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppTheme.Layout.tilePadding)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .fill(AppTheme.Accent.critical.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .strokeBorder(AppTheme.Accent.critical.opacity(0.16), lineWidth: 1)
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
