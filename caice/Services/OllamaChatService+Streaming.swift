import Foundation

extension OllamaChatService {

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
        } catch let error as URLError where isOllamaConnectionFailure(error) {
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
}
