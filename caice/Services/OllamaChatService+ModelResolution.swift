import Foundation

extension OllamaChatService {

    func resolveModelNameForRequest() async throws -> String {
        let configured = currentModelName()
        if configured != Self.autoModelMarker {
            return configured
        }

        let resolved = try await fetchFirstInstalledModelName()
        updateModel(resolved)
        return resolved
    }

    func fetchFirstInstalledModelName() async throws -> String {
        var request = URLRequest(url: baseURL.appending(path: "api/tags"))
        request.httpMethod = "GET"
        request.timeoutInterval = 3.0

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where isOllamaConnectionFailure(error) {
            throw ServiceError.serverUnavailable(baseURL)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown Ollama error"
            throw ServiceError.badStatus(httpResponse.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        guard let firstModel = decoded.models.first?.name,
              !firstModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ServiceError.emptyResponse
        }

        return firstModel
    }
}
