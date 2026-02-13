import Foundation

struct DownloadRequest: Sendable {
    let sourceURL: URL
    let title: String
    let preset: DownloadPreset
    let outputDirectory: URL
}
