import Foundation

enum AppDestination: String, CaseIterable, Hashable, Identifiable {
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
