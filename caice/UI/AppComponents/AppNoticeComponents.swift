import SwiftUI

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
                .fill(tint.opacity(0.1))
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
                .fill(AppTheme.Accent.success.opacity(0.1))
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
                .fill(AppTheme.Accent.critical.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.compactTile, style: .continuous)
                .strokeBorder(AppTheme.Accent.critical.opacity(0.16), lineWidth: 1)
        )
    }
}
