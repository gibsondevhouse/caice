import Foundation

enum OllamaServiceStatus: Equatable {
    case checking
    case offline
    case starting
    case restarting
    case running

    var title: String {
        switch self {
        case .checking:
            return "Checking Ollama"
        case .offline:
            return "Ollama Offline"
        case .starting:
            return "Starting Ollama"
        case .restarting:
            return "Restarting Ollama"
        case .running:
            return "Ollama Running"
        }
    }

    var systemImage: String {
        switch self {
        case .checking:
            return "magnifyingglass"
        case .offline:
            return "bolt.slash"
        case .starting, .restarting:
            return "arrow.triangle.2.circlepath"
        case .running:
            return "checkmark.circle.fill"
        }
    }
}

struct OllamaModelInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let sizeDescription: String?
    let detailDescription: String?
    let metadataDescription: String?

    init(
        name: String,
        sizeDescription: String?,
        detailDescription: String?,
        metadataDescription: String?
    ) {
        self.id = name
        self.name = name
        self.sizeDescription = sizeDescription
        self.detailDescription = detailDescription
        self.metadataDescription = metadataDescription
    }
}
