import SwiftUI

#Preview {
    ContentView(
        viewModel: ChatViewModel(service: MockChatService()),
        runtime: ChatRuntimeDescriptor(
            provider: .mock,
            providerName: "Mock",
            modelName: "Local Preview",
            contextWindowTokens: nil,
            endpointURL: nil,
            endpoint: nil,
            statusSummary: "UI-only mode"
        )
    )
}
