import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var key: String
    var pythonExecutablePath: String
    var ytdlpExecutablePath: String
    var downloadDirectoryPath: String
    var createdAt: Date
    var updatedAt: Date

    init(
        key: String = "default",
        pythonExecutablePath: String = "/usr/bin/python3",
        ytdlpExecutablePath: String = "/usr/local/bin/yt-dlp",
        downloadDirectoryPath: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.key = key
        self.pythonExecutablePath = pythonExecutablePath
        self.ytdlpExecutablePath = ytdlpExecutablePath
        self.downloadDirectoryPath = downloadDirectoryPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
