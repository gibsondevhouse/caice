import Foundation

#if os(macOS)
import AppKit
#endif

struct OllamaRuntimeState: Equatable {
    let isAppInstalled: Bool
    let isAppRunning: Bool
    let isReachable: Bool
}

protocol OllamaRuntimeControlling {
    func probe(endpointURL: URL) async -> OllamaRuntimeState
    func start(endpointURL: URL) async throws -> OllamaRuntimeState
    func restart(endpointURL: URL) async throws -> OllamaRuntimeState
}

struct OllamaRuntimeController: OllamaRuntimeControlling {
    enum RuntimeError: LocalizedError {
        case timedOutStarting(URL)

        var errorDescription: String? {
            switch self {
            case .timedOutStarting(let endpointURL):
                return "Ollama did not become reachable at \(endpointURL.absoluteString) in time."
            }
        }
    }

    private static let bundleIdentifier = "com.electron.ollama"

    private let session: URLSession
    private let readinessTimeoutNanoseconds: UInt64
    private let pollingIntervalNanoseconds: UInt64

    init(
        session: URLSession = OllamaRuntimeController.makeSession(),
        readinessTimeoutNanoseconds: UInt64 = 15_000_000_000,
        pollingIntervalNanoseconds: UInt64 = 500_000_000
    ) {
        self.session = session
        self.readinessTimeoutNanoseconds = readinessTimeoutNanoseconds
        self.pollingIntervalNanoseconds = pollingIntervalNanoseconds
    }

    func probe(endpointURL: URL) async -> OllamaRuntimeState {
        let isInstalled = await installedApplicationURL() != nil
        let isRunning = await appIsRunning()
        let isReachable = await endpointIsReachable(endpointURL)

        return OllamaRuntimeState(
            isAppInstalled: isInstalled,
            isAppRunning: isRunning,
            isReachable: isReachable
        )
    }

    func start(endpointURL: URL) async throws -> OllamaRuntimeState {
        return try await waitUntilReachable(endpointURL)
    }

    func restart(endpointURL: URL) async throws -> OllamaRuntimeState {
        return try await waitUntilReachable(endpointURL)
    }

    private func waitUntilReachable(_ endpointURL: URL) async throws -> OllamaRuntimeState {
        let maximumAttempts = max(1, Int(readinessTimeoutNanoseconds / pollingIntervalNanoseconds))

        for attempt in 0..<maximumAttempts {
            let state = await probe(endpointURL: endpointURL)
            if state.isReachable {
                return state
            }

            if attempt < maximumAttempts - 1 {
                try await Task.sleep(nanoseconds: pollingIntervalNanoseconds)
            }
        }

        throw RuntimeError.timedOutStarting(endpointURL)
    }

    private func endpointIsReachable(_ endpointURL: URL) async -> Bool {
        let candidates = endpointCandidates(from: endpointURL)
        for candidate in candidates {
            if await endpointCandidateIsReachable(candidate) {
                return true
            }
        }

        return false
    }

    private func endpointCandidateIsReachable(_ endpointURL: URL) async -> Bool {
        var request = URLRequest(url: endpointURL.appending(path: "api/tags"))
        request.httpMethod = "GET"
        request.timeoutInterval = 3.0

        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            return (200...299).contains(httpResponse.statusCode)
        } catch {
            return false
        }
    }

    private func endpointCandidates(from endpointURL: URL) -> [URL] {
        var candidates = [endpointURL]
        guard let alternateURL = alternateLoopbackURL(for: endpointURL) else {
            return candidates
        }

        candidates.append(alternateURL)
        return candidates
    }

    private func alternateLoopbackURL(for endpointURL: URL) -> URL? {
        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        guard let host = components.host?.lowercased() else {
            return nil
        }

        switch host {
        case "127.0.0.1":
            components.host = "localhost"
        case "localhost":
            components.host = "127.0.0.1"
        default:
            return nil
        }

        return components.url
    }

    private func installedApplicationURL() async -> URL? {
#if os(macOS)
        return await MainActor.run {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleIdentifier)
        }
#else
        return nil
#endif
    }

    private func appIsRunning() async -> Bool {
#if os(macOS)
        return await MainActor.run {
            !NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier).isEmpty
        }
#else
        return false
#endif
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 3.0
        configuration.timeoutIntervalForResource = 3.0
        return URLSession(configuration: configuration)
    }
}