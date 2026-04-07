import Foundation

struct ChatRuntimeDescriptor: Sendable {
    enum Provider: String, Sendable {
        case ollama
        case mock
    }

    let provider: Provider
    let providerName: String
    let modelName: String
    let contextWindowTokens: Int?
    let endpointURL: URL?
    let endpoint: String?
    let statusSummary: String
}

struct ChatServiceResolution {
    let service: any ChatService
    let runtime: ChatRuntimeDescriptor
}
