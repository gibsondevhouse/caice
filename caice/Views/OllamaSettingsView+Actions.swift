import SwiftUI

extension OllamaSettingsView {
    func performPrimaryConnectionAction() async {
        if viewModel.canStartService {
            await viewModel.startOllama()
            return
        }

        if viewModel.canRestartService {
            await viewModel.restartOllama()
        }
    }

    func applyContextWindow() {
        let sanitized = contextWindowText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else {
            onSelectContextWindow(nil)
            return
        }

        guard let parsed = Int(sanitized), parsed >= 256 else {
            return
        }

        contextWindowText = String(parsed)
        onSelectContextWindow(parsed)
    }

    func humanReadableTokenCount(_ count: Int) -> String {
        if count >= 1000 {
            return "\(count / 1000)K tokens"
        }

        return "\(count) tokens"
    }
}
