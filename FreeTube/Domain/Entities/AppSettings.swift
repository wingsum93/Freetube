import Foundation
import SwiftData

@Model
final class AppSettings {
    static let defaultKey = "default"
    static let defaultPythonExecutablePath = "/usr/bin/python3"
    static let defaultYTDLPExecutablePath = "/usr/local/bin/yt-dlp"

    @Attribute(.unique) var key: String
    var pythonExecutablePath: String
    var ytdlpExecutablePath: String
    var downloadDirectoryPath: String
    var createdAt: Date
    var updatedAt: Date

    init(
        key: String = AppSettings.defaultKey,
        pythonExecutablePath: String = AppSettings.defaultPythonExecutablePath,
        ytdlpExecutablePath: String = AppSettings.defaultYTDLPExecutablePath,
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
