import Foundation

final class OllamaChatService: ChatService {
    static let autoModelMarker = "__caice_auto__"

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

    private let baseURL: URL
    private let session: URLSession
    private let lock = NSLock()
    private var configuredModelName: String
    private var configuredContextWindowTokens: Int?

    init(
        configuration: Configuration,
        session: URLSession = .shared
    ) {
        self.baseURL = configuration.baseURL
        self.configuredModelName = configuration.model
        self.configuredContextWindowTokens = configuration.contextWindowTokens
        self.session = session
    }

    func updateModel(_ model: String) {
        let sanitized = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return }

        lock.lock()
        configuredModelName = sanitized
        lock.unlock()
    }

    func updateContextWindow(_ tokens: Int?) {
        if let tokens, tokens < 256 {
            return
        }

        lock.lock()
        configuredContextWindowTokens = tokens
        lock.unlock()
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        try await send(
            conversation: conversation,
            newMessage: newMessage,
            onDelta: { _ in }
        )
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String,
        onDelta: @escaping (String) async -> Void
    ) async throws -> String {
        let endpoint = baseURL.appending(path: "api/chat")

        let modelName = try await resolveModelNameForRequest()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        let payload = OllamaRequestPayload(
            model: modelName,
            stream: true,
            options: OllamaRequestPayload.Options(numCtx: currentContextWindowTokens()),
            messages: conversation.map { message in
                OllamaRequestPayload.Message(role: message.role.rawValue, content: message.text)
            }
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let bytes: URLSession.AsyncBytes
        let response: URLResponse

        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch let error as URLError where isConnectionFailure(error) {
            throw ServiceError.serverUnavailable(baseURL)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            var body = ""
            for try await line in bytes.lines {
                body.append(line)
            }
            if body.isEmpty {
                body = "Unknown Ollama error"
            }
            throw ServiceError.badStatus(httpResponse.statusCode, body)
        }

        var collected = ""
        let decoder = JSONDecoder()

        for try await line in bytes.lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            let lineData = Data(trimmedLine.utf8)

            let chunk: OllamaStreamResponsePayload
            do {
                chunk = try decoder.decode(OllamaStreamResponsePayload.self, from: lineData)
            } catch {
                if let payload = try? decoder.decode(OllamaStreamErrorPayload.self, from: lineData),
                   !payload.error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw ServiceError.badStatus(httpResponse.statusCode, payload.error)
                }

                // Ignore malformed chunk lines and continue collecting deltas.
                continue
            }

            let delta = chunk.message?.content ?? ""
            if !delta.isEmpty {
                collected.append(delta)
                await onDelta(delta)
            }

            if chunk.done {
                break
            }
        }

        let text = collected.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw ServiceError.emptyResponse
        }

        return text
    }

    private func currentModelName() -> String {
        lock.lock()
        defer { lock.unlock() }
        return configuredModelName
    }

    private func currentContextWindowTokens() -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return configuredContextWindowTokens
    }

    private func resolveModelNameForRequest() async throws -> String {
        let configured = currentModelName()
        if configured != Self.autoModelMarker {
            return configured
        }

        let resolved = try await fetchFirstInstalledModelName()
        updateModel(resolved)
        return resolved
    }

    private func fetchFirstInstalledModelName() async throws -> String {
        var request = URLRequest(url: baseURL.appending(path: "api/tags"))
        request.httpMethod = "GET"
        request.timeoutInterval = 3.0

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where isConnectionFailure(error) {
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

private struct OllamaRequestPayload: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct Options: Encodable {
        let numCtx: Int?

        enum CodingKeys: String, CodingKey {
            case numCtx = "num_ctx"
        }
    }

    let model: String
    let stream: Bool
    let options: Options?
    let messages: [Message]
}

private struct OllamaStreamResponsePayload: Decodable {
    struct Message: Decodable {
        let role: String
        let content: String
    }

    let message: Message?
    let done: Bool
}

private struct OllamaStreamErrorPayload: Decodable {
    let error: String
}