import Foundation

extension ChatViewModel {

    func reconcileModelIfNeeded(endpointURL: URL, runtimeModelName: String) async -> String? {
        guard !didAttemptModelReconciliation else { return nil }
        didAttemptModelReconciliation = true

        guard let installedModels = try? await fetchInstalledModelNames(endpointURL: endpointURL),
              let firstInstalledModel = installedModels.first else {
            return nil
        }

        let needsReconcile = runtimeModelName == ChatServiceFactory.automaticModelLabel
            || !installedModels.contains(runtimeModelName)

        guard needsReconcile else { return nil }

        updateModel(firstInstalledModel)
        return firstInstalledModel
    }

    func fetchInstalledModelNames(endpointURL: URL) async throws -> [String] {
        var request = URLRequest(url: endpointURL.appending(path: "api/tags"))
        request.httpMethod = "GET"
        request.timeoutInterval = 3.0

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return []
        }

        let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return decoded.models.map(\.name)
    }

    func userFacingErrorText(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }

        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty {
            return description
        }

        return "Could not send message."
    }
}
