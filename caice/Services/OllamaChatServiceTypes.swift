import Foundation

extension OllamaChatService {
    struct Configuration: Sendable {
        let baseURL: URL
        let model: String
        let contextWindowTokens: Int?

        init(baseURL: URL, model: String, contextWindowTokens: Int? = nil) {
            self.baseURL = baseURL
            self.model = model
            self.contextWindowTokens = contextWindowTokens
        }
    }

    enum ServiceError: LocalizedError {
        case serverUnavailable(URL)
        case invalidResponse
        case badStatus(Int, String)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .serverUnavailable(let baseURL):
                return "Ollama is not reachable at \(baseURL.absoluteString). Start Ollama and try again."
            case .invalidResponse:
                return "Invalid Ollama response."
            case .badStatus(let status, let message):
                return "Ollama error \(status): \(message)"
            case .emptyResponse:
                return "Ollama returned an empty response."
            }
        }
    }
}
