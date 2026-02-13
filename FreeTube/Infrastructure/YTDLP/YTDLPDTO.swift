import Foundation

struct VideoMetadataDTO: Decodable, Sendable {
    let id: String
    let title: String
    let uploader: String?
    let thumbnail: String?
    let duration: Double?
    let webpageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case uploader
        case thumbnail
        case duration
        case webpageURL = "webpage_url"
    }
}
