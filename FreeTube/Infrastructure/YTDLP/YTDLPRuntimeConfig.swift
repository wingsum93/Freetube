import Foundation

struct YTDLPRuntimeConfig: Sendable {
    let pythonExecutablePath: String
    let ytdlpExecutablePath: String
    let defaultTimeoutSeconds: TimeInterval

    init(
        pythonExecutablePath: String,
        ytdlpExecutablePath: String,
        defaultTimeoutSeconds: TimeInterval = 30
    ) {
        self.pythonExecutablePath = pythonExecutablePath
        self.ytdlpExecutablePath = ytdlpExecutablePath
        self.defaultTimeoutSeconds = defaultTimeoutSeconds
    }
}
