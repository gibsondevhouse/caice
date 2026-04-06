import Foundation

struct OllamaTagsResponse: Decodable {
    struct Model: Decodable {
        struct Details: Decodable {
            let family: String?
            let parameterSize: String?
            let quantizationLevel: String?

            private enum CodingKeys: String, CodingKey {
                case family
                case parameterSize = "parameter_size"
                case quantizationLevel = "quantization_level"
            }
        }

        let name: String
        let size: Int64?
        let modifiedAt: String?
        let details: Details?

        private enum CodingKeys: String, CodingKey {
            case name
            case size
            case modifiedAt = "modified_at"
            case details
        }

        var formattedModifiedAt: String? {
            guard let modifiedAt,
                  let date = ISO8601DateFormatter.ollamaModifiedAt.date(from: modifiedAt) else {
                return nil
            }

            return DateFormatter.ollamaModifiedAt.string(from: date)
        }
    }

    let models: [Model]
}

private extension ISO8601DateFormatter {
    static let ollamaModifiedAt: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

private extension DateFormatter {
    static let ollamaModifiedAt: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
