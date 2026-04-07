import Foundation

extension OllamaSettingsViewModel {

    var configuredModelInstalled: Bool {
        availableModels.contains { $0.name == selectedModelName }
    }

    var canStartService: Bool {
        serviceStatus != .starting && serviceStatus != .restarting && !isReachable
    }

    var canRestartService: Bool {
        serviceStatus != .starting && serviceStatus != .restarting
    }

    var hasLoadedModels: Bool {
        !availableModels.isEmpty
    }

    var isReachable: Bool {
        serviceStatus == .running
    }

    func loadModelsIfNeeded() async {
        guard !hasLoaded else { return }
        await refreshStatus()
    }

    func selectConfiguredModel(_ modelName: String) {
        let sanitized = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return }
        selectedModelName = sanitized
        onConfiguredModelChange(sanitized)

        if hasLoadedModels {
            statusDetailText = configuredModelInstalled
                ? "Loaded \(availableModels.count) installed model\(availableModels.count == 1 ? "" : "s") from your local Ollama runtime."
                : "Loaded \(availableModels.count) installed model\(availableModels.count == 1 ? "" : "s"), but \(selectedModelName) is not installed locally."
        }
    }
}
