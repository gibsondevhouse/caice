import Foundation
import Testing
@testable import caice

@Suite(.serialized)
struct OllamaChatServiceTests {

    @Test func configuredContextWindowIsSentInChatPayload() async throws {
        let capturedNumCtx = LockedOptionalInt(nil)

        let session = makeChatSession { request in
            if request.url?.path == "/api/chat" {
                if let body = requestBodyData(from: request),
                   let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                   let options = json["options"] as? [String: Any],
                   let numCtx = options["num_ctx"] as? Int {
                    capturedNumCtx.set(numCtx)
                }

                return (
                    200,
                    """
                    {"message":{"role":"assistant","content":"ok"},"done":true}
                    """
                )
            }

            return (404, "")
        }

        let service = OllamaChatService(
            configuration: .init(
                baseURL: try #require(URL(string: "http://localhost:11434")),
                model: "qwen3.5:9b",
                contextWindowTokens: 4096
            ),
            session: session
        )

        let response = try await service.send(
            conversation: [ChatMessage(role: .user, text: "hello")],
            newMessage: "hello"
        )

        #expect(response == "ok")
        #expect(capturedNumCtx.get() == 4096)
    }

    @Test func malformedStreamChunkIsIgnored() async throws {
        let session = makeChatSession { request in
            if request.url?.path == "/api/chat" {
                return (
                    200,
                    """
                    {"message":{"role":"assistant","content":"hel"},"done":false}
                    not-json
                    {"message":{"role":"assistant","content":"lo"},"done":true}
                    """
                )
            }

            return (404, "")
        }

        let service = OllamaChatService(
            configuration: .init(
                baseURL: try #require(URL(string: "http://localhost:11434")),
                model: "llama3.2"
            ),
            session: session
        )

        var deltas: [String] = []
        let result = try await service.send(
            conversation: [ChatMessage(role: .user, text: "hello")],
            newMessage: "hello",
            onDelta: { delta in
                deltas.append(delta)
            }
        )

        #expect(result == "hello")
        #expect(deltas == ["hel", "lo"])
    }

    @Test func streamErrorPayloadSurfacesServiceError() async throws {
        let session = makeChatSession { request in
            if request.url?.path == "/api/chat" {
                return (
                    200,
                    """
                    {"message":{"role":"assistant","content":"hel"},"done":false}
                    {"error":"model overloaded"}
                    """
                )
            }

            return (404, "")
        }

        let service = OllamaChatService(
            configuration: .init(
                baseURL: try #require(URL(string: "http://localhost:11434")),
                model: "llama3.2"
            ),
            session: session
        )

        var deltas: [String] = []

        do {
            _ = try await service.send(
                conversation: [ChatMessage(role: .user, text: "hello")],
                newMessage: "hello",
                onDelta: { delta in
                    deltas.append(delta)
                }
            )
            Issue.record("Expected bad status error")
        } catch let error as OllamaChatService.ServiceError {
            switch error {
            case .badStatus(let status, let message):
                #expect(status == 200)
                #expect(message == "model overloaded")
            default:
                Issue.record("Unexpected error: \(error)")
            }
        }

        #expect(deltas == ["hel"])
    }

    @Test func emptyModelListThrowsEmptyResponseWhenResolvingAutoModel() async throws {
        let session = makeChatSession { request in
            if request.url?.path == "/api/tags" {
                return (
                    200,
                    """
                    {
                      "models": []
                    }
                    """
                )
            }

            if request.url?.path == "/api/chat" {
                return (500, "")
            }

            return (404, "")
        }

        let service = OllamaChatService(
            configuration: .init(
                baseURL: try #require(URL(string: "http://localhost:11434")),
                model: OllamaChatService.autoModelMarker
            ),
            session: session
        )

        do {
            _ = try await service.send(
                conversation: [ChatMessage(role: .user, text: "hello")],
                newMessage: "hello"
            )
            Issue.record("Expected empty response error")
        } catch let error as OllamaChatService.ServiceError {
            if case .emptyResponse = error {
                #expect(true)
            } else {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }
}

private func makeChatSession(
    handler: @escaping @Sendable (URLRequest) -> (Int, String)
) -> URLSession {
    OllamaChatURLProtocol.handler = handler
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [OllamaChatURLProtocol.self]
    return URLSession(configuration: configuration)
}

private final class OllamaChatURLProtocol: URLProtocol, @unchecked Sendable {
    static var handler: (@Sendable (URLRequest) -> (Int, String))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let result = handler(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: result.0,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(result.1.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class LockedOptionalInt: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Int?

    init(_ value: Int?) {
        self.value = value
    }

    func get() -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set(_ newValue: Int?) {
        lock.lock()
        value = newValue
        lock.unlock()
    }
}

private func requestBodyData(from request: URLRequest) -> Data? {
    if let body = request.httpBody {
        return body
    }

    guard let bodyStream = request.httpBodyStream else {
        return nil
    }

    bodyStream.open()
    defer { bodyStream.close() }

    var data = Data()
    let bufferSize = 4096
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while bodyStream.hasBytesAvailable {
        let bytesRead = bodyStream.read(buffer, maxLength: bufferSize)
        if bytesRead > 0 {
            data.append(buffer, count: bytesRead)
        } else {
            break
        }
    }

    return data.isEmpty ? nil : data
}
