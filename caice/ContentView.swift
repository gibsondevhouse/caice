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
        case runtime

        var id: String { rawValue }

        var title: String {
            switch self {
            case .chat:
                return "Chat"
            case .runtime:
                return "Runtime"
            }
        }

        var systemImage: String {
            switch self {
            case .chat:
                return "bubble.left.and.bubble.right.fill"
            case .runtime:
                return "cpu"
            }
        }
    }

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
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
#endif
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section("Workspace") {
                Label("Caice", systemImage: "sparkle")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                NavigationLink(value: SidebarDestination.chat) {
                    sidebarRow(
                        title: "Chat",
                        subtitle: "\(viewModel.messages.count) messages",
                        systemImage: SidebarDestination.chat.systemImage
                    )
                }
            }

            Section("Runtime") {
                NavigationLink(value: SidebarDestination.runtime) {
                    sidebarRow(
                        title: runtime.providerName,
                        subtitle: "Configured: \(runtime.modelName)",
                        systemImage: SidebarDestination.runtime.systemImage
                    )
                }
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
        case .runtime:
            providerDetailView
        }
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            messagesSection

            Divider()

            composerSection
                .padding(12)
                .background(.thinMaterial)
        }
        .navigationTitle("Chat")
        .toolbarTitleDisplayMode(.inline)
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
        .navigationTitle("Runtime")
    }

    private func runtimeLine(title: String, value: String) -> some View {
        LabeledContent(title, value: value)
    }

    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if viewModel.messages.isEmpty {
                        Text("Start a conversation")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
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
        VStack(spacing: 8) {
            if let errorText = viewModel.errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $viewModel.composerText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                if viewModel.isSending {
                    Button("Cancel") {
                        viewModel.cancelCurrentSend()
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    Task {
                        await viewModel.sendCurrentMessage()
                    }
                } label: {
                    if viewModel.isSending {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSending || viewModel.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
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
