import Foundation

protocol YTDLPClient {
    func fetchVideoMetadata(url: URL) async throws -> VideoMetadataDTO
    func resolveStreamURL(videoURL: URL, format: StreamFormat) async throws -> URL
    func download(request: DownloadRequest) async throws -> URL
}

final class YTDLPProcessClient: YTDLPClient {
    private let runtimeConfig: YTDLPRuntimeConfig
    private let runtimeValidator: RuntimeValidator
    private let commandBuilder: YTDLPCommandBuilder
    private let processRunner: ProcessRunning

    init(
        runtimeConfig: YTDLPRuntimeConfig,
        runtimeValidator: RuntimeValidator = RuntimeValidator(),
        commandBuilder: YTDLPCommandBuilder = YTDLPCommandBuilder(),
        processRunner: ProcessRunning = ProcessRunner()
    ) {
        self.runtimeConfig = runtimeConfig
        self.runtimeValidator = runtimeValidator
        self.commandBuilder = commandBuilder
        self.processRunner = processRunner
    }

    func fetchVideoMetadata(url: URL) async throws -> VideoMetadataDTO {
        try runtimeValidator.validate(config: runtimeConfig)
        let output = try await processRunner.run(
            executablePath: runtimeConfig.ytdlpExecutablePath,
            arguments: commandBuilder.metadataArguments(videoURL: url),
            timeout: runtimeConfig.defaultTimeoutSeconds
        )

        guard output.terminationStatus == 0 else {
            throw RuntimeError.commandFailed(
                command: "yt-dlp metadata",
                status: output.terminationStatus,
                error: output.stderr
            )
        }

        guard let data = output.stdout.data(using: .utf8) else {
            throw RuntimeError.outputDecodeFailed
        }

        do {
            return try JSONDecoder().decode(VideoMetadataDTO.self, from: data)
        } catch {
            throw RuntimeError.outputDecodeFailed
        }
    }

    func resolveStreamURL(videoURL: URL, format: StreamFormat) async throws -> URL {
        try runtimeValidator.validate(config: runtimeConfig)
        let output = try await processRunner.run(
            executablePath: runtimeConfig.ytdlpExecutablePath,
            arguments: commandBuilder.streamURLArguments(videoURL: videoURL, format: format),
            timeout: runtimeConfig.defaultTimeoutSeconds
        )

        guard output.terminationStatus == 0 else {
            throw RuntimeError.commandFailed(
                command: "yt-dlp stream URL",
                status: output.terminationStatus,
                error: output.stderr
            )
        }

        guard let firstLine = output.stdout
            .split(separator: "\n")
            .map(String.init)
            .first(where: { !$0.isEmpty }),
              let url = URL(string: firstLine) else {
            throw RuntimeError.outputDecodeFailed
        }

        return url
    }

    func download(request: DownloadRequest) async throws -> URL {
        try runtimeValidator.validate(config: runtimeConfig)
        try FileManager.default.createDirectory(at: request.outputDirectory, withIntermediateDirectories: true)

        let outputFile = commandBuilder.outputFileURL(for: request)
        let arguments = commandBuilder.downloadArguments(request: request, outputFile: outputFile)

        let output = try await processRunner.run(
            executablePath: runtimeConfig.ytdlpExecutablePath,
            arguments: arguments,
            timeout: nil
        )

        guard output.terminationStatus == 0 else {
            throw RuntimeError.commandFailed(
                command: "yt-dlp download",
                status: output.terminationStatus,
                error: output.stderr
            )
        }

        return outputFile
    }
}
