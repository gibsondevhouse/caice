import Foundation
import Combine

@MainActor
final class OllamaSettingsViewModel: ObservableObject {
    @Published var availableModels: [OllamaModelInfo] = []
    @Published var isLoading: Bool = false
    @Published var serviceStatus: OllamaServiceStatus = .checking
    @Published var statusDetailText: String?
    @Published var lastCheckedAt: Date?
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