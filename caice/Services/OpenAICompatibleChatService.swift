import Foundation

struct OpenAICompatibleChatService: ChatService {
    struct Configuration: Sendable {
        let baseURL: URL
        let apiKey: String
        let model: String

        init(baseURL: URL, apiKey: String, model: String) {
            self.baseURL = baseURL
            self.apiKey = apiKey
            self.model = model
        }
    }

    enum ServiceError: LocalizedError {
        case invalidResponse
        case badStatus(Int, String)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid provider response."
            case .badStatus(let status, let message):
                return "Provider error \(status): \(message)"
            case .emptyResponse:
                return "Provider returned an empty response."
            }
        }
    }

    private let configuration: Configuration
    private let session: URLSession

    init(
        configuration: Configuration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        let endpoint = configuration.baseURL.appending(path: "chat/completions")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        let payload = RequestPayload(
            model: configuration.model,
            messages: conversation.map { message in
                RequestPayload.Message(role: message.role.rawValue, content: message.text)
            }
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown provider error"
            throw ServiceError.badStatus(httpResponse.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(ResponsePayload.self, from: data)
        guard let text = decoded.choices.first?.message.content,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw ServiceError.emptyResponse
        }

        return text
    }
}

private struct RequestPayload: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
}

private struct ResponsePayload: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}
