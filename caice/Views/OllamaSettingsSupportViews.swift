import SwiftUI

struct ContextPreset: Identifiable {
    let title: String
    let subtitle: String
    let value: Int?

    var id: String { title }
}

struct ContextPresetButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        AppActionTile(isSelected: isSelected, action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.accentColor.opacity(0.8) : .secondary)
            }
        }
    }
}

struct OllamaModelCard: View {
    let model: OllamaSettingsViewModel.ModelInfo
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 10) {
                        Text(model.name)
                            .font(.title3.weight(.semibold))

                        if isSelected {
                            AppStatusBadge(title: "Active", color: .accentColor, systemImage: "checkmark.circle.fill")
                        }
                    }

                    if let detailDescription = model.detailDescription {
                        Text(detailDescription)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    if let metadataDescription = model.metadataDescription {
                        Text(metadataDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 20)

                VStack(alignment: .trailing, spacing: 8) {
                    if isSelected {
                        Text("Installed and in use")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if isSelected {
                        Button("Selected") {
                            onSelect()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(true)
                    } else {
                        Button("Use Model") {
                            onSelect()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
        }
    }
}
