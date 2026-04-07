import Foundation

enum ChatServiceFactory {
    static let ollamaModelDefaultsKey = "caice.ollama.model"
    static let ollamaContextWindowDefaultsKey = "caice.ollama.context_window"
    static let automaticModelLabel = "Auto"

    static func makeDefaultService(
        environment: [String: String]? = nil,
        defaults: UserDefaults = .standard
    ) -> any ChatService {
        resolveDefaultService(environment: environment, defaults: defaults).service
    }

    static func resolveDefaultService(
        environment: [String: String]? = nil,
        defaults: UserDefaults = .standard
    ) -> ChatServiceResolution {
        let resolvedEnvironment = environment ?? ProcessInfo.processInfo.environment
        let useMock = resolvedEnvironment["CAICE_USE_MOCK"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if useMock == "1" || useMock == "true" || useMock == "yes" {
            return ChatServiceResolution(
                service: MockChatService(),
                runtime: ChatRuntimeDescriptor(
                    provider: .mock,
                    providerName: "Mock",
                    modelName: "Local Preview",
                    contextWindowTokens: nil,
                    endpointURL: nil,
                    endpoint: nil,
                    statusSummary: "UI-only mode"
                )
            )
        }

        let baseURLString = resolvedEnvironment["CAICE_OLLAMA_BASE_URL"] ?? "http://127.0.0.1:11434"
        guard let parsedBaseURL = URL(string: baseURLString) else {
            return ChatServiceResolution(
                service: MockChatService(),
                runtime: ChatRuntimeDescriptor(
                    provider: .mock,
                    providerName: "Mock",
                    modelName: "Local Preview",
                    contextWindowTokens: nil,
                    endpointURL: nil,
                    endpoint: nil,
                    statusSummary: "Invalid Ollama URL, using mock"
                )
            )
        }
        let baseURL = normalizedOllamaBaseURL(parsedBaseURL)

        let explicitModel = resolvedEnvironment["CAICE_OLLAMA_MODEL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let explicitContextWindow = parseContextWindow(from: resolvedEnvironment["CAICE_OLLAMA_CONTEXT_WINDOW"])
        let persistedModel: String?
        let persistedContextWindow: Int?
        if environment == nil {
            persistedModel = defaults.string(forKey: ollamaModelDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let persisted = defaults.integer(forKey: ollamaContextWindowDefaultsKey)
            persistedContextWindow = persisted > 0 ? persisted : nil
        } else {
            persistedModel = nil
            persistedContextWindow = nil
        }

        let contextWindow = explicitContextWindow ?? persistedContextWindow

        let serviceModelName: String
        let runtimeModelName: String
        if let explicitModel, !explicitModel.isEmpty {
            serviceModelName = explicitModel
            runtimeModelName = explicitModel
        } else if let persistedModel, !persistedModel.isEmpty {
            serviceModelName = persistedModel
            runtimeModelName = persistedModel
        } else {
            serviceModelName = OllamaChatService.autoModelMarker
            runtimeModelName = automaticModelLabel
        }

        let configuration = OllamaChatService.Configuration(
            baseURL: baseURL,
            model: serviceModelName,
            contextWindowTokens: contextWindow
        )

        return ChatServiceResolution(
            service: OllamaChatService(configuration: configuration),
            runtime: ChatRuntimeDescriptor(
                provider: .ollama,
                providerName: "Ollama",
                modelName: runtimeModelName,
                contextWindowTokens: contextWindow,
                endpointURL: baseURL,
                endpoint: baseURL.absoluteString,
                statusSummary: "Local model runtime"
            )
        )
    }

    private static func normalizedOllamaBaseURL(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        let normalizedPath = components.path.lowercased()
        if normalizedPath == "/api" || normalizedPath == "/api/" || normalizedPath == "/v1" || normalizedPath == "/v1/" {
            components.path = ""
            return components.url ?? url
        }

        return url
    }

    private static func parseContextWindow(from rawValue: String?) -> Int? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Int(trimmed), parsed >= 256 else {
            return nil
        }

        return parsed
    }
}
