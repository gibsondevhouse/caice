import Foundation
import Combine

@MainActor
final class OllamaSettingsViewModel: ObservableObject {
    @Published internal(set) var availableModels: [OllamaModelInfo] = []
    @Published internal(set) var isLoading: Bool = false
    @Published internal(set) var serviceStatus: OllamaServiceStatus = .checking
    @Published internal(set) var statusDetailText: String?
    @Published internal(set) var lastCheckedAt: Date?
    @Published var selectedModelName: String
    @Published var errorText: String?

    let endpointURL: URL

    let session: URLSession
    let runtimeController: any OllamaRuntimeControlling
    let onConfiguredModelChange: (String) -> Void
    var hasLoaded = false

    init(
        endpointURL: URL,
        selectedModelName: String,
        session: URLSession = .shared,
        onConfiguredModelChange: @escaping (String) -> Void = { _ in }
    ) {
        self.endpointURL = endpointURL
        self.selectedModelName = selectedModelName
        self.session = session
        self.runtimeController = OllamaRuntimeController()
        self.onConfiguredModelChange = onConfiguredModelChange
    }

    init(
        endpointURL: URL,
        selectedModelName: String,
        session: URLSession = .shared,
        runtimeController: any OllamaRuntimeControlling,
        onConfiguredModelChange: @escaping (String) -> Void = { _ in }
    ) {
        self.endpointURL = endpointURL
        self.selectedModelName = selectedModelName
        self.session = session
        self.runtimeController = runtimeController
        self.onConfiguredModelChange = onConfiguredModelChange
    }

}