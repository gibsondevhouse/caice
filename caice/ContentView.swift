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
                return "Home"
            case .modelSettings:
                return "Model Settings"
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
        "Brainstorm a product idea I can ship in two weekends",
        "Help me debug a SwiftUI state update issue",
        "Draft a concise, professional email",
        "Summarize these notes into action items",
        "Plan a feature rollout checklist for V1",
        "Rewrite this message to be clearer and shorter"
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
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
#endif
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section {
                Button {
                    viewModel.beginNewChat()
                    selection = .chat
                } label: {
                    Label("New Chat", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }

            Section {
                NavigationLink(value: SidebarDestination.chat) {
                    sidebarRow(
                        title: "Chat Workspace",
                        subtitle: "\(viewModel.messages.count) messages",
                        systemImage: SidebarDestination.chat.systemImage
                    )
                }

                NavigationLink(value: SidebarDestination.modelSettings) {
                    sidebarRow(
                        title: "Model Settings",
                        subtitle: runtime.modelName,
                        systemImage: SidebarDestination.modelSettings.systemImage
                    )
                }
            } header: {
                Text("Navigate")
            }
        }
        .navigationTitle("Caice")
        .listStyle(.sidebar)
    }

    private func sidebarRow(title: String, subtitle: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: systemImage)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
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
            ChatHeaderView(
                title: "AI Workspace",
                subtitle: viewModel.messages.isEmpty
                    ? "Start with a prompt to begin a local conversation."
                    : "Continue the conversation with \(runtime.modelName)."
            )
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            messagesSection

            composerSection
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
        .navigationTitle("Caice")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                HStack(spacing: 10) {
                    Label(runtime.modelName, systemImage: "cpu")
                    Label(runtimeBadgeText, systemImage: runtimeBadgeSymbol)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var providerDetailView: some View {
        if runtime.provider == .ollama,
           let endpointURL = runtime.endpointURL {
            OllamaSettingsView(
                endpointURL: endpointURL,
                selectedModelName: runtime.modelName,
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
                        endpointURL: runtime.endpointURL,
                        endpoint: runtime.endpoint,
                        statusSummary: runtime.statusSummary
                    )
                    viewModel.updateModel(modelName)
                }
            )
        } else {
            runtimeView
        }
    }

    private var runtimeView: some View {
        List {
            Section("Provider") {
                runtimeLine(title: "Backend", value: runtime.providerName)
                runtimeLine(title: "Model", value: runtime.modelName)
                runtimeLine(title: "Status", value: runtime.statusSummary)
                if let endpoint = runtime.endpoint {
                    runtimeLine(title: "Endpoint", value: endpoint)
                }
            }

            Section("Conversation") {
                runtimeLine(title: "Messages", value: "\(viewModel.messages.count)")
                runtimeLine(title: "Sending", value: viewModel.isSending ? "In progress" : "Idle")
                if let errorText = viewModel.errorText {
                    runtimeLine(title: "Last Error", value: errorText)
                }
            }
        }
        .navigationTitle("Model Settings")
    }

    private func runtimeLine(title: String, value: String) -> some View {
        LabeledContent(title, value: value)
    }

    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if viewModel.messages.isEmpty {
                        HomeEmptyStateView(prompts: starterPrompts) { prompt in
                            viewModel.prefillComposer(with: prompt)
                        }
                        .padding(.top, 12)
                    }

                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
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
            modelName: runtime.modelName,
            statusText: runtimeBadgeText,
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

    private var runtimeBadgeSymbol: String {
        if viewModel.isSending {
            return "arrow.triangle.2.circlepath"
        }
        if viewModel.errorText != nil {
            return "exclamationmark.triangle"
        }
        return "checkmark.circle"
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
            endpointURL: nil,
            endpoint: nil,
            statusSummary: "UI-only mode"
        )
    )
}
