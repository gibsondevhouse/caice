//
//  ContentView.swift
//  caice
//
//  Created by Christopher Gibson on 4/5/26.
//

import SwiftUI

struct ContentView: View {
    private enum SidebarDestination: String, CaseIterable, Hashable, Identifiable {
        case chat
        case modelSettings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .chat:
                return "Chat"
            case .modelSettings:
                return "Models"
            }
        }

        var systemImage: String {
            switch self {
            case .chat:
                return "bubble.left.and.bubble.right.fill"
            case .modelSettings:
                return "slider.horizontal.3"
            }
        }
    }

    private let starterPrompts = [
        "Brainstorm a product idea I can ship this month",
        "Help me debug a SwiftUI state issue",
        "Draft a concise professional email",
        "Summarize these notes into action items"
    ]

    @StateObject private var viewModel: ChatViewModel
    @State private var selection: SidebarDestination? = .chat
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
            sidebar
        } detail: {
            detailContent
        }
        .task {
            await reconcileRuntimeModelIfNeeded()
        }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 138, ideal: 154, max: 170)
#endif
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                viewModel.beginNewChat()
                selection = .chat
            } label: {
                Label("New Chat", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)

            Divider()
                .opacity(0.35)

            sidebarDestinationButton(
                destination: .chat,
                title: "Chat",
                subtitle: viewModel.messages.isEmpty ? "No messages" : "\(viewModel.messages.count) messages"
            )

            sidebarDestinationButton(
                destination: .modelSettings,
                title: "Models",
                subtitle: runtime.modelName
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .navigationTitle("Caice")
    }

    private func sidebarDestinationButton(
        destination: SidebarDestination,
        title: String,
        subtitle: String
    ) -> some View {
        AppSidebarRow(
            title: title,
            subtitle: subtitle,
            systemImage: destination.systemImage,
            isSelected: selection == destination,
            action: {
                selection = destination
            }
        )
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection ?? .chat {
        case .chat:
            chatView
        case .modelSettings:
            providerDetailView
        }
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            workspaceHeader
                .padding(.horizontal, 36)
                .padding(.top, 30)
                .padding(.bottom, 8)

            if viewModel.messages.isEmpty {
                emptyWorkspaceContent
            } else {
                messagesSection
                    .frame(maxWidth: AppTheme.Layout.chatContentWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)
            }

            composerSection
                .frame(maxWidth: AppTheme.Layout.chatContentWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 36)
                .padding(.top, 10)
                .padding(.bottom, 20)
        }
        .navigationTitle("")
        .toolbarTitleDisplayMode(.inline)
    }

    private var workspaceHeader: some View {
        AppPageHeader(
            title: "Chat",
            subtitle: "Local | \(runtime.modelName) | \(runtimeBadgeText)",
            titleFont: .largeTitle.weight(.semibold),
            subtitleFont: .subheadline
        )
        .frame(maxWidth: AppTheme.Layout.chatContentWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyWorkspaceContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HomeEmptyStateView(prompts: starterPrompts) { prompt in
                viewModel.prefillComposer(with: prompt)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: AppTheme.Layout.chatContentWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 36)
        .padding(.top, 8)
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

    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) {
                if let lastID = viewModel.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamingRevision) {
                if let lastID = viewModel.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var composerSection: some View {
        ChatComposerView(
            text: $viewModel.composerText,
            isSending: viewModel.isSending,
            errorText: viewModel.errorText,
            onSend: {
                Task {
                    await viewModel.sendCurrentMessage()
                }
            },
            onCancel: {
                viewModel.cancelCurrentSend()
            }
        )
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
