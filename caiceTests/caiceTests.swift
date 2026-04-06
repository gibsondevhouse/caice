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
