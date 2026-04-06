import Foundation
import Combine

@MainActor
final class OllamaSettingsViewModel: ObservableObject {
    enum ServiceStatus: Equatable {
        case checking
        case offline
        case starting
        case restarting
        case running

        var title: String {
            switch self {
            case .checking:
                return "Checking Ollama"
            case .offline:
                return "Ollama Offline"
            case .starting:
                return "Starting Ollama"
            case .restarting:
                return "Restarting Ollama"
            case .running:
                return "Ollama Running"
            }
        }

        var systemImage: String {
            switch self {
            case .checking:
                return "magnifyingglass"
            case .offline:
                return "bolt.slash"
            case .starting, .restarting:
                return "arrow.triangle.2.circlepath"
            case .running:
                return "checkmark.circle.fill"
            }
        }
    }

    struct ModelInfo: Identifiable, Equatable {
        let id: String
        let name: String
        let sizeDescription: String?
        let detailDescription: String?
        let metadataDescription: String?

        init(
            name: String,
            sizeDescription: String?,
            detailDescription: String?,
            metadataDescription: String?
        ) {
            self.id = name
            self.name = name
            self.sizeDescription = sizeDescription
            self.detailDescription = detailDescription
            self.metadataDescription = metadataDescription
        }
    }

    @Published private(set) var availableModels: [ModelInfo] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var serviceStatus: ServiceStatus = .checking
    @Published private(set) var statusDetailText: String?
    @Published private(set) var lastCheckedAt: Date?
    @Published private(set) var selectedModelName: String
    @Published var errorText: String?

    let endpointURL: URL

    private let session: URLSession
    private let runtimeController: any OllamaRuntimeControlling
    private let onConfiguredModelChange: (String) -> Void
    private var hasLoaded = false

    init(
        endpointURL: URL,
        selectedModelName: String,
        session: URLSession = .shared,
        onConfiguredModelChange: @escaping (String) -> Void = { _ in }
    ) {
        self.endpointURL = endpointURL
        self.selectedModelName = selectedModelName
        self.session = session
        self.runtimeController = OllamaRuntimeController()
        self.onConfiguredModelChange = onConfiguredModelChange
    }

    init(
        endpointURL: URL,
        selectedModelName: String,
        session: URLSession = .shared,
        runtimeController: any OllamaRuntimeControlling,
        onConfiguredModelChange: @escaping (String) -> Void = { _ in }
    ) {
        self.endpointURL = endpointURL
        self.selectedModelName = selectedModelName
        self.session = session
        self.runtimeController = runtimeController
        self.onConfiguredModelChange = onConfiguredModelChange
    }

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

    func loadModelsIfNeeded() async {
        guard !hasLoaded else { return }
        await refreshStatus()
    }

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
        } catch let error as URLError where isConnectionFailure(error) {
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

    private func fetchModels() async throws -> [ModelInfo] {
        var request = URLRequest(url: endpointURL.appending(path: "api/tags"))
        request.httpMethod = "GET"
        request.timeoutInterval = 3.0

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaSettingsError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown Ollama error"
            throw OllamaSettingsError.badStatus(httpResponse.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return decoded.models
            .map { model in
                var detailParts: [String] = []

                if let family = model.details?.family, !family.isEmpty {
                    detailParts.append(family)
                }

                if let parameterSize = model.details?.parameterSize, !parameterSize.isEmpty {
                    detailParts.append(parameterSize)
                }

                if let quantizationLevel = model.details?.quantizationLevel, !quantizationLevel.isEmpty {
                    detailParts.append(quantizationLevel)
                }

                let sizeDescription = model.size.map {
                    ByteCountFormatter.string(fromByteCount: $0, countStyle: .file)
                }

                let metadataParts = [
                    sizeDescription,
                    model.formattedModifiedAt
                ]

                return ModelInfo(
                    name: model.name,
                    sizeDescription: sizeDescription,
                    detailDescription: detailParts.isEmpty ? nil : detailParts.joined(separator: " • "),
                    metadataDescription: metadataParts.compactMap { $0 }.joined(separator: " • ")
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func apply(_ runtimeState: OllamaRuntimeState) {
        if runtimeState.isReachable {
            serviceStatus = .running
            statusDetailText = "Ollama is responding at \(endpointURL.absoluteString)."
        } else {
            serviceStatus = .offline
            statusDetailText = "Ollama API is not responding at \(endpointURL.absoluteString)."
        }
    }

    @discardableResult
    private func reconcileConfiguredModelIfNeeded() -> String? {
        guard !availableModels.isEmpty else { return nil }
        guard !configuredModelInstalled else { return nil }

        let fallbackModelName = availableModels[0].name
        selectConfiguredModel(fallbackModelName)
        return fallbackModelName
    }
}

private enum OllamaSettingsError: LocalizedError {
    case invalidResponse
    case badStatus(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response while loading Ollama models."
        case .badStatus(let status, let body):
            return "Ollama returned \(status): \(body)"
        }
    }
}

private func isConnectionFailure(_ error: URLError) -> Bool {
    switch error.code {
    case .cannotConnectToHost,
         .cannotFindHost,
         .networkConnectionLost,
         .notConnectedToInternet,
         .timedOut:
        return true
    default:
        return false
    }
}