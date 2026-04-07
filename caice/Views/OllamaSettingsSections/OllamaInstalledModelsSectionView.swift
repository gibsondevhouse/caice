import SwiftUI

struct OllamaInstalledModelsSectionView: View {
    let isLoading: Bool
    let availableModels: [OllamaModelInfo]
    let selectedModelName: String
    let onSelectModel: (String) -> Void

    var body: some View {
        AppSection(title: "Installed Models", subtitle: "Choose from models reported directly by your local Ollama runtime.") {
            if isLoading && availableModels.isEmpty {
                AppCard {
                    HStack(spacing: 12) {
                        ProgressView()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Refreshing local models")
                                .font(.headline)
                            Text("Caice is fetching the installed model list from your Ollama daemon.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else if availableModels.isEmpty {
                AppCard {
                    ContentUnavailableView(
                        "No Local Models",
                        systemImage: "shippingbox",
                        description: Text("Install or pull a model in Ollama, then refresh the runtime status here.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(availableModels) { model in
                        OllamaModelCard(
                            model: model,
                            isSelected: model.name == selectedModelName,
                            onSelect: {
                                onSelectModel(model.name)
                            }
                        )
                    }
                }
            }
        }
    }
}
