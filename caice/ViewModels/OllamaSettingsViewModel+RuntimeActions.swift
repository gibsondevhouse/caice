import Foundation

extension OllamaSettingsViewModel {

    func refreshStatus() async {
        guard !isLoading else { return }

        isLoading = true
        errorText = nil
        serviceStatus = hasLoaded ? serviceStatus : .checking
        defer {
            isLoading = false
            lastCheckedAt = Date()
        }

        let runtimeState = await runtimeController.probe(endpointURL: endpointURL)
        apply(runtimeState)

        guard runtimeState.isReachable else {
            availableModels = []
            errorText = "Ollama is not reachable at \(endpointURL.absoluteString). Ensure the daemon is running (for example: ollama serve) and refresh."
            hasLoaded = true
            return
        }

        do {
            availableModels = try await fetchModels()
            let autoSelectedModel = reconcileConfiguredModelIfNeeded()
            if let autoSelectedModel {
                statusDetailText = "Loaded \(availableModels.count) installed model\(availableModels.count == 1 ? "" : "s") and switched to \(autoSelectedModel) because the previous model was not installed locally."
            } else {
                statusDetailText = configuredModelInstalled
                    ? "Loaded \(availableModels.count) installed model\(availableModels.count == 1 ? "" : "s") from your local Ollama runtime."
                    : "Loaded \(availableModels.count) installed model\(availableModels.count == 1 ? "" : "s"), but \(selectedModelName) is not installed locally."
            }
            hasLoaded = true
        } catch let error as URLError where isOllamaConnectionFailure(error) {
            availableModels = []
            serviceStatus = .offline
            errorText = "Ollama is not reachable at \(endpointURL.absoluteString). Ensure the daemon is running (for example: ollama serve) and refresh."
        } catch let error as LocalizedError {
            availableModels = []
            errorText = error.errorDescription ?? "Could not load Ollama models."
        } catch {
            availableModels = []
            errorText = error.localizedDescription
        }
    }

    func startOllama() async {
        guard canStartService else { return }

        errorText = nil
        serviceStatus = .starting
        statusDetailText = "Checking connectivity to the Ollama API endpoint."

        do {
            let runtimeState = try await runtimeController.connect(endpointURL: endpointURL)
            apply(runtimeState)
            await refreshStatus()
        } catch let error as LocalizedError {
            serviceStatus = .offline
            errorText = error.errorDescription ?? "Could not start Ollama."
        } catch {
            serviceStatus = .offline
            errorText = error.localizedDescription
        }
    }

    func restartOllama() async {
        guard canRestartService else { return }

        errorText = nil
        serviceStatus = .restarting
        statusDetailText = "Re-checking connectivity to the Ollama API endpoint."

        do {
            let runtimeState = try await runtimeController.connect(endpointURL: endpointURL)
            apply(runtimeState)
            await refreshStatus()
        } catch let error as LocalizedError {
            serviceStatus = .offline
            errorText = error.errorDescription ?? "Could not restart Ollama."
        } catch {
            serviceStatus = .offline
            errorText = error.localizedDescription
        }
    }
}
