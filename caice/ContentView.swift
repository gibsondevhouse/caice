//
//  ContentView.swift
//  caice
//
//  Created by Christopher Gibson on 4/5/26.
//

import SwiftUI

struct ContentView: View {
    private let starterPrompts = [
        "Brainstorm a product idea I can ship this month",
        "Help me debug a SwiftUI state issue",
        "Draft a concise professional email",
        "Summarize these notes into action items"
    ]

    @StateObject private var viewModel: ChatViewModel
    @State private var selection: AppDestination? = .chat
    @State private var runtime: ChatRuntimeDescriptor

    init(
        viewModel: @autoclosure @escaping () -> ChatViewModel,
        runtime: ChatRuntimeDescriptor
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        _runtime = State(initialValue: runtime)
    }

    var body: some View {
        NavigationSplitView {
            AppSidebarView(
                selection: $selection,
                messageCount: viewModel.messages.count,
                runtimeModelName: runtime.modelName,
                onNewChat: {
                    viewModel.beginNewChat()
                }
            )
        } detail: {
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.Surface.windowBackground)
        }
        .task {
            await reconcileRuntimeModelIfNeeded()
        }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 138, ideal: 154, max: 170)
#endif
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection ?? .chat {
        case .chat:
            ChatWorkspaceView(
                runtimeModelName: runtime.modelName,
                runtimeBadgeText: runtimeBadgeText,
                starterPrompts: starterPrompts,
                messages: viewModel.messages,
                streamingRevision: viewModel.streamingRevision,
                composerText: $viewModel.composerText,
                isSending: viewModel.isSending,
                errorText: viewModel.errorText,
                onPromptSelected: { prompt in
                    viewModel.prefillComposer(with: prompt)
                },
                onSend: {
                    Task {
                        await viewModel.sendCurrentMessage()
                    }
                },
                onCancel: {
                    viewModel.cancelCurrentSend()
                }
            )
        case .modelSettings:
            providerDetailView
        }
    }

    @ViewBuilder
    private var providerDetailView: some View {
        if runtime.provider == .ollama,
           let endpointURL = runtime.endpointURL {
            OllamaSettingsView(
                endpointURL: endpointURL,
                selectedModelName: runtime.modelName,
                selectedContextWindowTokens: runtime.contextWindowTokens,
                providerName: runtime.providerName,
                statusSummary: runtime.statusSummary,
                messageCount: viewModel.messages.count,
                isSending: viewModel.isSending,
                lastError: viewModel.errorText,
                onSelectModel: { modelName in
                    runtime = ChatRuntimeDescriptor(
                        provider: runtime.provider,
                        providerName: runtime.providerName,
                        modelName: modelName,
                        contextWindowTokens: runtime.contextWindowTokens,
                        endpointURL: runtime.endpointURL,
                        endpoint: runtime.endpoint,
                        statusSummary: runtime.statusSummary
                    )
                    viewModel.updateModel(modelName)
                },
                onSelectContextWindow: { tokens in
                    runtime = ChatRuntimeDescriptor(
                        provider: runtime.provider,
                        providerName: runtime.providerName,
                        modelName: runtime.modelName,
                        contextWindowTokens: tokens,
                        endpointURL: runtime.endpointURL,
                        endpoint: runtime.endpoint,
                        statusSummary: runtime.statusSummary
                    )
                    viewModel.updateContextWindow(tokens)
                }
            )
        } else {
            RuntimeSummaryView(
                providerName: runtime.providerName,
                modelName: runtime.modelName,
                statusSummary: runtime.statusSummary,
                endpoint: runtime.endpoint,
                messageCount: viewModel.messages.count,
                isSending: viewModel.isSending,
                lastError: viewModel.errorText
            )
        }
    }

    private var runtimeBadgeText: String {
        if viewModel.isSending {
            return "Responding"
        }
        if viewModel.errorText != nil {
            return "Needs Attention"
        }
        return "Ready"
    }

    private func reconcileRuntimeModelIfNeeded() async {
        guard runtime.provider == .ollama,
              let endpointURL = runtime.endpointURL else {
            return
        }

        guard let reconciledModel = await viewModel.reconcileModelIfNeeded(
            endpointURL: endpointURL,
            runtimeModelName: runtime.modelName
        ) else {
            return
        }

        runtime = ChatRuntimeDescriptor(
            provider: runtime.provider,
            providerName: runtime.providerName,
            modelName: reconciledModel,
            contextWindowTokens: runtime.contextWindowTokens,
            endpointURL: runtime.endpointURL,
            endpoint: runtime.endpoint,
            statusSummary: runtime.statusSummary
        )
    }
}

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
