import SwiftUI

extension OllamaSettingsView {
    var pageHeader: some View {
        AppPageHeader(
            title: "Ollama",
            subtitle: "Tune your local runtime for speed, memory use, and model selection without dropping into daemon-level tooling."
        )
    }

    var connectionSection: some View {
        OllamaConnectionSectionView(
            statusTitle: viewModel.serviceStatus.title,
            statusColor: serviceStatusColor,
            statusSystemImage: viewModel.serviceStatus.systemImage,
            statusDetailText: viewModel.statusDetailText,
            errorText: viewModel.errorText,
            endpointURL: viewModel.endpointURL,
            providerName: providerName,
            statusSummary: statusSummary,
            lastCheckedLabel: lastCheckedLabel,
            primaryActionTitle: primaryConnectionActionTitle,
            isLoading: viewModel.isLoading,
            canStartService: viewModel.canStartService,
            canRestartService: viewModel.canRestartService,
            onPrimaryAction: {
                Task {
                    await performPrimaryConnectionAction()
                }
            },
            onRefresh: {
                Task {
                    await viewModel.refreshStatus()
                }
            }
        )
    }

    var activeModelSection: some View {
        OllamaActiveModelSectionView(
            selectedModelName: viewModel.selectedModelName,
            activeContextSummary: activeContextSummary,
            hasLoadedModels: viewModel.hasLoadedModels,
            configuredModelInstalled: viewModel.configuredModelInstalled,
            currentContextWindowValue: currentContextWindowValue,
            contextPresets: contextPresets,
            contextWindowText: $contextWindowText,
            onSelectContextPreset: onSelectContextWindow,
            onApplyContextWindow: applyContextWindow,
            onResetContextWindow: {
                onSelectContextWindow(nil)
            }
        )
    }

    var installedModelsSection: some View {
        OllamaInstalledModelsSectionView(
            isLoading: viewModel.isLoading,
            availableModels: viewModel.availableModels,
            selectedModelName: viewModel.selectedModelName,
            onSelectModel: { modelName in
                viewModel.selectConfiguredModel(modelName)
            }
        )
    }

    var advancedSection: some View {
        OllamaAdvancedSectionView(
            isExpanded: $isAdvancedExpanded,
            messageCount: messageCount,
            isSending: isSending,
            selectedModelName: viewModel.selectedModelName,
            contextWindowText: contextWindowText,
            lastError: lastError,
            endpointURL: viewModel.endpointURL
        )
    }
}
