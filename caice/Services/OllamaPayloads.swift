import Foundation

struct OllamaRequestPayload: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct Options: Encodable {
        let numCtx: Int?

        enum CodingKeys: String, CodingKey {
            case numCtx = "num_ctx"
        }
    }

    let model: String
    let stream: Bool
    let options: Options?
    let messages: [Message]
}

struct OllamaStreamResponsePayload: Decodable {
    struct Message: Decodable {
        let role: String
        let content: String
    }

    let message: Message?
    let done: Bool
}

struct OllamaStreamErrorPayload: Decodable {
    let error: String
}
