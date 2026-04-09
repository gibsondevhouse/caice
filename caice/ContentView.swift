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
    @State private var availableModelNames: [String] = []
    @State private var renameThreadID: UUID?
    @State private var renameThreadTitle: String = ""
    @State private var isShowingRenamePrompt = false
    @State private var deleteThreadID: UUID?
    @State private var isShowingDeleteConfirmation = false
    @State private var recentlyDeletedThread: ChatThread?
    @State private var showUndoDeleteBanner = false
    @State private var undoDismissWorkItem: DispatchWorkItem?

    init(
        viewModel: @autoclosure @escaping () -> ChatViewModel,
        runtime: ChatRuntimeDescriptor
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        _runtime = State(initialValue: runtime)
    }

    var body: some View {
        rootContainer
            .task {
                await reconcileRuntimeModelIfNeeded()
                await refreshAvailableModels()
            }
            .overlay(alignment: .bottom) {
                if showUndoDeleteBanner {
                    undoDeleteBanner
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .alert("Rename Conversation", isPresented: $isShowingRenamePrompt) {
                TextField("Conversation name", text: $renameThreadTitle)
                Button("Save") {
                    guard let renameThreadID else { return }
                    viewModel.renameThread(id: renameThreadID, to: renameThreadTitle)
                    self.renameThreadID = nil
                }
                Button("Cancel", role: .cancel) {
                    renameThreadID = nil
                }
            } message: {
                Text("Give this conversation a short descriptive title.")
            }
            .confirmationDialog(
                "Delete Conversation?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    guard let deleteThreadID else { return }
                    performDelete(threadID: deleteThreadID)
                }

                Button("Cancel", role: .cancel) {
                    deleteThreadID = nil
                }
            } message: {
                Text("\(viewModel.threadTitle(for: deleteThreadID)) will be removed from local history.")
            }
            .onDisappear {
                undoDismissWorkItem?.cancel()
                undoDismissWorkItem = nil
            }
    }

    @ViewBuilder
    private var rootContainer: some View {
#if os(macOS)
        HStack(spacing: 0) {
            sidebarContent
                .frame(width: AppTheme.Layout.sidebarWidth)

            Divider()

            detailPane
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailPane
        }
#endif
    }

    private var sidebarContent: some View {
        AppSidebarView(
            selection: $selection,
            messageCount: viewModel.messages.count,
            runtimeModelName: runtime.modelName,
            threads: viewModel.threadSummaries,
            selectedThreadID: viewModel.selectedThreadID,
            isSending: viewModel.isSending,
            onNewChat: {
                viewModel.beginNewChat()
            },
            onSelectThread: { threadID in
                viewModel.selectThread(threadID)
            },
            onRequestRenameThread: { threadID in
                DispatchQueue.main.async {
                    renameThreadID = threadID
                    renameThreadTitle = viewModel.threadTitle(for: threadID)
                    isShowingDeleteConfirmation = false
                    isShowingRenamePrompt = true
                }
            },
            onRequestDeleteThread: { threadID in
                DispatchQueue.main.async {
                    if viewModel.shouldConfirmDelete(for: threadID) {
                        deleteThreadID = threadID
                        isShowingRenamePrompt = false
                        isShowingDeleteConfirmation = true
                    } else {
                        performDelete(threadID: threadID)
                    }
                }
            }
        )
    }

    private var undoDeleteBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .foregroundStyle(.secondary)

            Text("Conversation deleted")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            Button("Undo") {
                undoDeletedThread()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppTheme.Surface.stroke, lineWidth: 1)
        )
    }

    private var detailPane: some View {
        detailContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    AppTheme.Surface.appBackdropGradient

                    Circle()
                        .fill(AppTheme.Surface.warmGlow.opacity(0.16))
                        .frame(width: 540, height: 540)
                        .blur(radius: 80)
                        .offset(x: -240, y: -280)

                    Circle()
                        .fill(AppTheme.Surface.coolGlow.opacity(0.12))
                        .frame(width: 500, height: 500)
                        .blur(radius: 90)
                        .offset(x: 260, y: -220)
                }
            }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection ?? .chat {
        case .chat:
            ChatWorkspaceView(
                conversationTitle: viewModel.selectedThreadTitle,
                runtimeModelName: runtime.modelName,
                runtimeBadgeText: runtimeBadgeText,
                availableModelNames: availableModelNames,
                starterPrompts: starterPrompts,
                messages: viewModel.messages,
                streamingRevision: viewModel.streamingRevision,
                composerText: $viewModel.composerText,
                isSending: viewModel.isSending,
                errorText: viewModel.errorText,
                onPromptSelected: { prompt in
                    viewModel.prefillComposer(with: prompt)
                },
                onSelectModel: { modelName in
                    runtime = descriptor(overridingModel: modelName)
                    viewModel.updateModel(modelName)
                },
                onSend: {
                    Task {
                        await viewModel.sendCurrentMessage()
                    }
                },
                onSuggestionAction: { userVisibleMessage, modelPrompt in
                    Task {
                        await viewModel.sendSuggestionAction(
                            displayText: userVisibleMessage,
                            modelPrompt: modelPrompt
                        )
                    }
                },
                onCancel: {
                    viewModel.cancelCurrentSend()
                }
            )
        case .modelSettings:
            ProviderDetailPaneView(
                runtime: runtime,
                messageCount: viewModel.messages.count,
                isSending: viewModel.isSending,
                lastError: viewModel.errorText,
                onSelectModel: { modelName in
                    runtime = descriptor(overridingModel: modelName)
                    viewModel.updateModel(modelName)
                },
                onSelectContextWindow: { tokens in
                    runtime = descriptor(overridingContextWindow: tokens)
                    viewModel.updateContextWindow(tokens)
                }
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

        runtime = descriptor(overridingModel: reconciledModel)
    }

    private func refreshAvailableModels() async {
        guard let endpointURL = runtime.endpointURL else { return }
        let names = (try? await viewModel.fetchInstalledModelNames(endpointURL: endpointURL)) ?? []
        availableModelNames = names
    }

    private func descriptor(
        overridingModel modelName: String? = nil,
        overridingContextWindow contextWindowTokens: Int?? = nil
    ) -> ChatRuntimeDescriptor {
        ChatRuntimeDescriptor(
            provider: runtime.provider,
            providerName: runtime.providerName,
            modelName: modelName ?? runtime.modelName,
            contextWindowTokens: contextWindowTokens ?? runtime.contextWindowTokens,
            endpointURL: runtime.endpointURL,
            endpoint: runtime.endpoint,
            statusSummary: runtime.statusSummary
        )
    }

    private func performDelete(threadID: UUID) {
        isShowingDeleteConfirmation = false
        let deletedThread = viewModel.deleteThread(id: threadID)
        deleteThreadID = nil

        guard let deletedThread else { return }
        recentlyDeletedThread = deletedThread
        showUndoDeleteBanner = true

        undoDismissWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            clearUndoState()
        }
        undoDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
    }

    private func undoDeletedThread() {
        guard let recentlyDeletedThread else { return }
        viewModel.restoreDeletedThread(recentlyDeletedThread)
        clearUndoState()
    }

    private func clearUndoState() {
        undoDismissWorkItem?.cancel()
        undoDismissWorkItem = nil
        recentlyDeletedThread = nil
        withAnimation {
            showUndoDeleteBanner = false
        }
    }
}
