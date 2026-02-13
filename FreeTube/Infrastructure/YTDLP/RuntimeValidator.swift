import Foundation

struct RuntimeValidator {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func validate(config: YTDLPRuntimeConfig) throws {
        try validateExecutable(at: config.pythonExecutablePath)
        try validateExecutable(at: config.ytdlpExecutablePath)
    }

    private func validateExecutable(at path: String) throws {
        guard fileManager.fileExists(atPath: path) else {
            throw RuntimeError.missingExecutable(path: path)
        }

        guard fileManager.isExecutableFile(atPath: path) else {
            throw RuntimeError.nonExecutable(path: path)
        }
    }
}
