import Foundation

extension OllamaSettingsViewModel {

    func fetchModels() async throws -> [OllamaModelInfo] {
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

                return OllamaModelInfo(
                    name: model.name,
                    sizeDescription: sizeDescription,
                    detailDescription: detailParts.isEmpty ? nil : detailParts.joined(separator: " • "),
                    metadataDescription: metadataParts.compactMap { $0 }.joined(separator: " • ")
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func apply(_ runtimeState: OllamaRuntimeState) {
        if runtimeState.isReachable {
            serviceStatus = .running
            statusDetailText = "Ollama is responding at \(endpointURL.absoluteString)."
        } else {
            serviceStatus = .offline
            statusDetailText = "Ollama API is not responding at \(endpointURL.absoluteString)."
        }
    }

    @discardableResult
    func reconcileConfiguredModelIfNeeded() -> String? {
        guard !availableModels.isEmpty else { return nil }
        guard !configuredModelInstalled else { return nil }

        let fallbackModelName = availableModels[0].name
        selectConfiguredModel(fallbackModelName)
        return fallbackModelName
    }
}

enum OllamaSettingsError: LocalizedError {
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
