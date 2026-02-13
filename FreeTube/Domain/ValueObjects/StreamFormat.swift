import Foundation

enum StreamFormat: Sendable {
    case bestCompatible
    case audioOnly
    case preset(DownloadPreset)
    case custom(String)
}
