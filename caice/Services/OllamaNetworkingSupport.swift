import Foundation

func isOllamaConnectionFailure(_ error: URLError) -> Bool {
    switch error.code {
    case .cannotConnectToHost,
         .cannotFindHost,
         .networkConnectionLost,
         .notConnectedToInternet,
         .timedOut:
        return true
    default:
        return false
    }
}
