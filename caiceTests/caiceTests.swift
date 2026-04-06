//
//  caiceTests.swift
//  caiceTests
//
//  Created by Christopher Gibson on 4/5/26.
//

import Foundation
import Testing
@testable import caice

struct caiceTests {

    @Test func factoryUsesOllamaServiceByDefault() {
        let resolution = ChatServiceFactory.resolveDefaultService(environment: [:])
        #expect(resolution.service is OllamaChatService)
        #expect(resolution.runtime.modelName == ChatServiceFactory.automaticModelLabel)
    }

    @Test func factoryUsesMockServiceWhenRequested() {
        let service = ChatServiceFactory.makeDefaultService(environment: [
            "CAICE_USE_MOCK": "true"
        ])
        #expect(service is MockChatService)
    }

    @Test func factoryUsesOllamaServiceWhenConfigured() {
        let service = ChatServiceFactory.makeDefaultService(environment: [
            "CAICE_OLLAMA_BASE_URL": "http://localhost:11434",
            "CAICE_OLLAMA_MODEL": "mistral"
        ])
        #expect(service is OllamaChatService)
    }

    @Test func factoryNormalizesDocumentedApiBaseURL() {
        let resolution = ChatServiceFactory.resolveDefaultService(environment: [
            "CAICE_OLLAMA_BASE_URL": "http://localhost:11434/api",
            "CAICE_OLLAMA_MODEL": "mistral"
        ])

        #expect(resolution.service is OllamaChatService)
        #expect(resolution.runtime.endpoint == "http://localhost:11434")
    }

    @Test func factoryNormalizesOpenAICompatV1BaseURL() {
        let resolution = ChatServiceFactory.resolveDefaultService(environment: [
            "CAICE_OLLAMA_BASE_URL": "http://localhost:11434/v1",
            "CAICE_OLLAMA_MODEL": "mistral"
        ])

        #expect(resolution.service is OllamaChatService)
        #expect(resolution.runtime.endpoint == "http://localhost:11434")
    }

    @Test func factoryNormalizesApiAndV1TrailingSlashBaseURLs() {
        let apiResolution = ChatServiceFactory.resolveDefaultService(environment: [
            "CAICE_OLLAMA_BASE_URL": "http://localhost:11434/api/",
            "CAICE_OLLAMA_MODEL": "mistral"
        ])

        let v1Resolution = ChatServiceFactory.resolveDefaultService(environment: [
            "CAICE_OLLAMA_BASE_URL": "http://localhost:11434/v1/",
            "CAICE_OLLAMA_MODEL": "mistral"
        ])

        #expect(apiResolution.runtime.endpoint == "http://localhost:11434")
        #expect(v1Resolution.runtime.endpoint == "http://localhost:11434")
    }

    @Test func factoryUsesPersistedOllamaModelWhenEnvironmentIsImplicit() {
        let defaults = UserDefaults(suiteName: "caice-tests.factory.persisted-model")!
        defaults.removePersistentDomain(forName: "caice-tests.factory.persisted-model")
        defaults.set("gemma3:4b", forKey: ChatServiceFactory.ollamaModelDefaultsKey)

        let resolution = ChatServiceFactory.resolveDefaultService(environment: nil, defaults: defaults)

        #expect(resolution.service is OllamaChatService)
        #expect(resolution.runtime.modelName == "gemma3:4b")

        defaults.removePersistentDomain(forName: "caice-tests.factory.persisted-model")
    }

    @MainActor
    @Test func sendAppendsUserAndAssistantMessages() async throws {
        let service = SucceedingService()
        let viewModel = ChatViewModel(service: service)

        viewModel.composerText = "hello"
        await viewModel.sendCurrentMessage()

        #expect(viewModel.messages.count == 2)
        #expect(viewModel.messages[0].role == .user)
        #expect(viewModel.messages[0].text == "hello")
        #expect(viewModel.messages[1].role == .assistant)
        #expect(viewModel.messages[1].text == "ok")
        #expect(viewModel.errorText == nil)
    }

    @MainActor
    @Test func streamingSendBuildsAssistantMessageFromDeltas() async throws {
        let service = StreamingService()
        let viewModel = ChatViewModel(service: service)

        viewModel.composerText = "hello"
        await viewModel.sendCurrentMessage()

        #expect(viewModel.messages.count == 2)
        #expect(viewModel.messages[1].role == .assistant)
        #expect(viewModel.messages[1].text == "hello there")
        #expect(viewModel.streamingRevision == 2)
    }

    @MainActor
    @Test func failedSendShowsErrorWithoutAssistantMessage() async throws {
        let service = FailingService()
        let viewModel = ChatViewModel(service: service)

        viewModel.composerText = "hello"
        await viewModel.sendCurrentMessage()

        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages[0].role == .user)
        #expect(viewModel.errorText == "Stub failure")
    }

    @MainActor
    @Test func sendPreservesPartialAssistantOnLateFailure() async throws {
        let service = LateFailureService()
        let viewModel = ChatViewModel(service: service)

        viewModel.composerText = "hello"
        await viewModel.sendCurrentMessage()

        #expect(viewModel.messages.count == 2)
        #expect(viewModel.messages[1].role == .assistant)
        #expect(viewModel.messages[1].text == "partial")
        #expect(viewModel.errorText == "Stream failed")
    }

    @MainActor
    @Test func cancelDuringStreamResetsSendingStateAndKeepsPartialTranscript() async throws {
        let service = SlowStreamingService()
        let viewModel = ChatViewModel(service: service)

        viewModel.composerText = "hello"
        let sendTask = Task {
            await viewModel.sendCurrentMessage()
        }

        for _ in 0..<100 {
            if viewModel.isSending {
                break
            }
            await Task.yield()
        }

        viewModel.cancelCurrentSend()
        await sendTask.value

        #expect(viewModel.isSending == false)
        #expect(viewModel.errorText == nil)
        #expect(viewModel.messages.count == 2)
        #expect(viewModel.messages[1].text == "partial")
    }

    @MainActor
    @Test func duplicateSendIsPreventedDuringInFlightRequest() async throws {
        let service = SlowStreamingService()
        let viewModel = ChatViewModel(service: service)

        viewModel.composerText = "first"
        let firstTask = Task {
            await viewModel.sendCurrentMessage()
        }

        for _ in 0..<100 {
            if viewModel.isSending {
                break
            }
            await Task.yield()
        }

        viewModel.composerText = "second"
        await viewModel.sendCurrentMessage()
        viewModel.cancelCurrentSend()
        await firstTask.value

        #expect(service.sendCallCount == 1)
        #expect(viewModel.messages.first?.text == "first")
    }

    @MainActor
    @Test func updateModelPersistsAndCallsService() async throws {
        let suiteName = "caice-tests.viewmodel.update-model"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let service = RecordingService()
        let viewModel = ChatViewModel(service: service, defaults: defaults)

        viewModel.updateModel("gemma3:4b")

        #expect(defaults.string(forKey: ChatServiceFactory.ollamaModelDefaultsKey) == "gemma3:4b")
        #expect(service.updatedModel == "gemma3:4b")

        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    @Test func reconcileModelReturnsInstalledFallbackAndUpdatesPersistence() async throws {
        let suiteName = "caice-tests.viewmodel.reconcile-model"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let service = RecordingService()
        let session = makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:11434/api/tags")
            return (
                200,
                """
                {
                  "models": [
                    { "name": "gemma3:4b" }
                  ]
                }
                """
            )
        }

        let viewModel = ChatViewModel(service: service, defaults: defaults, session: session)

        let reconciled = await viewModel.reconcileModelIfNeeded(
            endpointURL: try #require(URL(string: "http://127.0.0.1:11434")),
            runtimeModelName: ChatServiceFactory.automaticModelLabel
        )

        #expect(reconciled == "gemma3:4b")
        #expect(service.updatedModel == "gemma3:4b")
        #expect(defaults.string(forKey: ChatServiceFactory.ollamaModelDefaultsKey) == "gemma3:4b")

        defaults.removePersistentDomain(forName: suiteName)
    }

}

private struct SucceedingService: ChatService {
    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        "ok"
    }
}

private struct FailingService: ChatService {
    struct StubError: LocalizedError {
        var errorDescription: String? {
            "Stub failure"
        }
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        throw StubError()
    }
}

private struct StreamingService: ChatService {
    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        "hello there"
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String,
        onDelta: @escaping (String) async -> Void
    ) async throws -> String {
        await onDelta("hello")
        await onDelta(" there")
        return "hello there"
    }
}

private struct LateFailureService: ChatService {
    struct StubError: LocalizedError {
        var errorDescription: String? {
            "Stream failed"
        }
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        throw StubError()
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String,
        onDelta: @escaping (String) async -> Void
    ) async throws -> String {
        await onDelta("partial")
        throw StubError()
    }
}

@MainActor
private final class SlowStreamingService: ChatService {
    private(set) var sendCallCount = 0

    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        sendCallCount += 1
        try await Task.sleep(nanoseconds: 5_000_000_000)
        return "done"
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String,
        onDelta: @escaping (String) async -> Void
    ) async throws -> String {
        sendCallCount += 1
        await onDelta("partial")
        try await Task.sleep(nanoseconds: 5_000_000_000)
        return "done"
    }
}

@MainActor
private final class RecordingService: ChatService {
    private(set) var updatedModel: String?

    func updateModel(_ model: String) {
        updatedModel = model
    }

    func send(
        conversation: [ChatMessage],
        newMessage: String
    ) async throws -> String {
        "ok"
    }
}

private func makeSession(
    handler: @escaping @Sendable (URLRequest) -> (Int, String)
) -> URLSession {
    TestURLProtocol.handler = handler
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [TestURLProtocol.self]
    return URLSession(configuration: configuration)
}

private final class TestURLProtocol: URLProtocol, @unchecked Sendable {
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
