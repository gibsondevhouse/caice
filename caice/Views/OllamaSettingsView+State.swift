import SwiftUI

extension OllamaSettingsView {
    var currentContextWindowValue: Int? {
        let sanitized = contextWindowText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Int(sanitized), parsed >= 256 else {
            return nil
        }
        return parsed
    }

    var activeContextSummary: String {
        if let currentContextWindowValue {
            return "Context window set to \(humanReadableTokenCount(currentContextWindowValue))"
        }

        return "Context window is automatic"
    }

    var primaryConnectionActionTitle: String {
        "Reconnect"
    }

    var lastCheckedLabel: String {
        guard let lastCheckedAt = viewModel.lastCheckedAt else {
            return "Not checked yet"
        }

        return lastCheckedAt.formatted(date: .omitted, time: .shortened)
    }

    var serviceStatusColor: Color {
        switch viewModel.serviceStatus {
        case .checking:
            return AppTheme.Accent.neutral
        case .offline:
            return AppTheme.Accent.warning
        case .starting, .restarting:
            return AppTheme.Accent.info
        case .running:
            return AppTheme.Accent.success
        }
    }

    var contextPresets: [ContextPreset] {
        [
            ContextPreset(title: "Auto", subtitle: "Balanced", value: nil),
            ContextPreset(title: "4K", subtitle: "Fastest", value: 4096),
            ContextPreset(title: "8K", subtitle: "Recommended", value: 8192),
            ContextPreset(title: "16K", subtitle: "Longer Memory", value: 16384)
        ]
    }
}
