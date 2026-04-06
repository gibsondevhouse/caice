import Foundation
import Testing
@testable import caice

@Suite(.serialized)
struct OllamaSettingsViewModelTests {

    @MainActor
    @Test func loadModelsReturnsAvailableModels() async throws {
                let controller = StubRuntimeController(
                        probedState: OllamaRuntimeState(isAppInstalled: true, isAppRunning: true, isReachable: true)
                )
        let session = makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:11434/api/tags")
            return (
                200,
                """
                {
                  "models": [
                                        {
                                            "name": "llama3.2",
                                            "size": 2013265920,
                                            "modified_at": "2026-04-06T00:00:00.000000000-04:00",
                                            "details": {
                                                "family": "llama",
                                                "parameter_size": "3.2B",
                                                "quantization_level": "Q4_K_M"
                                            }
                                        },
                                        {
                                            "name": "mistral",
                                            "size": 4294967296,
                                            "modified_at": "2026-04-05T00:00:00.000000000-04:00",
                                            "details": {
                                                "family": "mistral",
                                                "parameter_size": "7B",
                                                "quantization_level": "Q4_0"
                                            }
                                        }
                  ]
                }
                """
            )
        }

        let viewModel = OllamaSettingsViewModel(
            endpointURL: try #require(URL(string: "http://127.0.0.1:11434")),
            selectedModelName: "llama3.2",
            session: session,
            runtimeController: controller
        )

        await viewModel.refreshStatus()

        #expect(viewModel.availableModels.map(\.name) == ["llama3.2", "mistral"])
        #expect(viewModel.errorText == nil)
        #expect(viewModel.serviceStatus == .running)
        #expect(viewModel.configuredModelInstalled)
        #expect(viewModel.availableModels.first?.detailDescription == "llama • 3.2B • Q4_K_M")
    }

    @MainActor
    @Test func loadModelsShowsConnectionErrorWhenUnavailable() async throws {
        let controller = StubRuntimeController(
            probedState: OllamaRuntimeState(isAppInstalled: true, isAppRunning: false, isReachable: false)
        )

        let viewModel = OllamaSettingsViewModel(
            endpointURL: try #require(URL(string: "http://127.0.0.1:11434")),
            selectedModelName: "llama3.2",
            runtimeController: controller
        )

        await viewModel.refreshStatus()

        #expect(viewModel.availableModels.isEmpty)
        #expect(viewModel.errorText == "Ollama is not reachable at http://127.0.0.1:11434. Ensure the daemon is running (for example: ollama serve) and refresh.")
        #expect(viewModel.serviceStatus == .offline)
    }

    @MainActor
    @Test func startOllamaLoadsInstalledModels() async throws {
        let controller = StubRuntimeController(
            probedState: OllamaRuntimeState(isAppInstalled: true, isAppRunning: false, isReachable: false),
            startState: OllamaRuntimeState(isAppInstalled: true, isAppRunning: true, isReachable: true)
        )
        let session = makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:11434/api/tags")
            return (
                200,
                """
                {
                  "models": [
                    { "name": "gemma3:4b", "size": 3338801804 }
                  ]
                }
                """
            )
        }

        let viewModel = OllamaSettingsViewModel(
            endpointURL: try #require(URL(string: "http://127.0.0.1:11434")),
            selectedModelName: "llama3.2",
            session: session,
            runtimeController: controller
        )

        await viewModel.refreshStatus()
        await viewModel.startOllama()

        #expect(controller.startCallCount == 1)
        #expect(viewModel.serviceStatus == .running)
        #expect(viewModel.availableModels.map(\.name) == ["gemma3:4b"])
        #expect(viewModel.selectedModelName == "gemma3:4b")
        #expect(viewModel.configuredModelInstalled)
    }

    @MainActor
    @Test func restartOllamaReloadsInstalledModels() async throws {
        let controller = StubRuntimeController(
            probedState: OllamaRuntimeState(isAppInstalled: true, isAppRunning: true, isReachable: true),
            restartState: OllamaRuntimeState(isAppInstalled: true, isAppRunning: true, isReachable: true)
        )
        let session = makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:11434/api/tags")
            return (
                200,
                """
                {
                  "models": [
                    { "name": "gemma3:4b", "size": 3338801804 },
                    { "name": "nomic-embed-text:latest", "size": 274877906 }
                  ]
                }
                """
            )
        }

        let viewModel = OllamaSettingsViewModel(
            endpointURL: try #require(URL(string: "http://127.0.0.1:11434")),
            selectedModelName: "gemma3:4b",
            session: session,
            runtimeController: controller
        )

        await viewModel.refreshStatus()
        await viewModel.restartOllama()

        #expect(controller.restartCallCount == 1)
        #expect(viewModel.serviceStatus == .running)
        #expect(viewModel.availableModels.map(\.name) == ["gemma3:4b", "nomic-embed-text:latest"])
        #expect(viewModel.configuredModelInstalled)
    }

    @MainActor
    @Test func refreshClearsStaleModelsWhenRuntimeBecomesUnavailable() async throws {
        let controller = StubRuntimeController(
            probedState: OllamaRuntimeState(isAppInstalled: true, isAppRunning: true, isReachable: true)
        )

        let responseBody = LockedString(
            """
            {
              "models": [
                { "name": "gemma3:4b", "size": 3338801804 }
              ]
            }
            """
        )

        let session = makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:11434/api/tags")
            return (200, responseBody.get())
        }

        let viewModel = OllamaSettingsViewModel(
            endpointURL: try #require(URL(string: "http://127.0.0.1:11434")),
            selectedModelName: "gemma3:4b",
            session: session,
            runtimeController: controller
        )

        await viewModel.refreshStatus()
        #expect(viewModel.availableModels.map(\.name) == ["gemma3:4b"])
        #expect(viewModel.serviceStatus == .running)

        controller.probedState = OllamaRuntimeState(isAppInstalled: true, isAppRunning: false, isReachable: false)
        await viewModel.refreshStatus()

        #expect(viewModel.availableModels.isEmpty)
        #expect(viewModel.serviceStatus == .offline)
        #expect(viewModel.errorText == "Ollama is not reachable at http://127.0.0.1:11434. Ensure the daemon is running (for example: ollama serve) and refresh.")
    }

    @MainActor
    @Test func refreshAutoSelectsInstalledModelWhenConfiguredModelIsStale() async throws {
        let controller = StubRuntimeController(
            probedState: OllamaRuntimeState(isAppInstalled: true, isAppRunning: true, isReachable: true)
        )

        let selectedModelCapture = LockedString("")
        let session = makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:11434/api/tags")
            return (
                200,
                """
                {
                  "models": [
                    { "name": "gemma3:4b", "size": 3338801804 },
                    { "name": "nomic-embed-text:latest", "size": 274877906 }
                  ]
                }
                """
            )
        }

        let viewModel = OllamaSettingsViewModel(
            endpointURL: try #require(URL(string: "http://127.0.0.1:11434")),
            selectedModelName: "llama3.2",
            session: session,
            runtimeController: controller,
            onConfiguredModelChange: { modelName in
                selectedModelCapture.set(modelName)
            }
        )

        await viewModel.refreshStatus()

        #expect(viewModel.selectedModelName == "gemma3:4b")
        #expect(viewModel.configuredModelInstalled)
        #expect(selectedModelCapture.get() == "gemma3:4b")
    }
}

@MainActor
private final class StubRuntimeController: OllamaRuntimeControlling {
    var probedState: OllamaRuntimeState
    var startState: OllamaRuntimeState
    var restartState: OllamaRuntimeState
    private(set) var startCallCount = 0
    private(set) var restartCallCount = 0

    init(
        probedState: OllamaRuntimeState,
        startState: OllamaRuntimeState? = nil,
        restartState: OllamaRuntimeState? = nil
    ) {
        self.probedState = probedState
        self.startState = startState ?? probedState
        self.restartState = restartState ?? self.startState
    }

    func probe(endpointURL: URL) async -> OllamaRuntimeState {
        probedState
    }

    func start(endpointURL: URL) async throws -> OllamaRuntimeState {
        startCallCount += 1
        probedState = startState
        return startState
    }

    func restart(endpointURL: URL) async throws -> OllamaRuntimeState {
        restartCallCount += 1
        probedState = restartState
        return restartState
    }
}

private func makeSession(
    handler: @escaping @Sendable (URLRequest) -> (Int, String)
) -> URLSession {
    MockURLProtocol.handler = handler
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
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

private final class LockedString: @unchecked Sendable {
    private let lock = NSLock()
    private var value: String

    init(_ value: String) {
        self.value = value
    }

    func get() -> String {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set(_ newValue: String) {
        lock.lock()
        value = newValue
        lock.unlock()
    }
}