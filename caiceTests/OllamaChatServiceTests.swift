import Foundation
import Testing
@testable import caice

@Suite(.serialized)
struct OllamaChatServiceTests {

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
