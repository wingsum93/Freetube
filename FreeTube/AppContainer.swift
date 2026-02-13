import AppKit
import Combine
import Foundation
import SwiftData

@MainActor
final class AppContainer: ObservableObject {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    let playlistRepository: PlaylistRepository
    let videoRepository: VideoRepository
    let downloadRepository: DownloadRepository

    private(set) var ytDLPClient: YTDLPClient
    private(set) var downloadManager: DownloadManager
    let playbackCoordinator: PlaylistPlaybackCoordinator

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext

        let playlistRepository = SwiftDataPlaylistRepository(modelContext: modelContainer.mainContext)
        let videoRepository = SwiftDataVideoRepository(modelContext: modelContainer.mainContext)
        let downloadRepository = SwiftDataDownloadRepository(modelContext: modelContainer.mainContext)

        self.playlistRepository = playlistRepository
        self.videoRepository = videoRepository
        self.downloadRepository = downloadRepository
        self.playbackCoordinator = PlaylistPlaybackCoordinator()

        do {
            let settings = try AppContainer.bootstrap(
                playlistRepository: playlistRepository,
                modelContext: modelContainer.mainContext
            )
            let runtimeConfig = YTDLPRuntimeConfig(
                pythonExecutablePath: settings.pythonExecutablePath,
                ytdlpExecutablePath: settings.ytdlpExecutablePath
            )
            self.ytDLPClient = YTDLPProcessClient(runtimeConfig: runtimeConfig)
        } catch {
            fatalError("Failed to bootstrap app data: \(error)")
        }

        self.downloadManager = DownloadManager(
            downloadRepository: downloadRepository,
            ytDLPClient: ytDLPClient
        )
    }

    func addClipboardYouTubeLink() async throws -> UUID {
        let useCase = AddClipboardYouTubeToCurrentListUseCase(
            playlistRepository: playlistRepository,
            videoRepository: videoRepository,
            ytDLPClient: ytDLPClient,
            downloadManager: downloadManager,
            clipboardStringProvider: {
                NSPasteboard.general.string(forType: .string)
            },
            downloadDirectoryProvider: { [weak self] in
                guard let self else {
                    throw AddClipboardYouTubeToCurrentListError.missingDownloadDirectory
                }
                return try self.resolveDownloadDirectory()
            }
        )

        return try await useCase.execute()
    }

    func removeCurrentListItem(itemID: UUID) async throws {
        let useCase = RemoveCurrentListItemUseCase(
            playlistRepository: playlistRepository,
            downloadRepository: downloadRepository,
            downloadManager: downloadManager
        )
        try await useCase.execute(itemID: itemID)
    }

    func currentExecutablePaths() throws -> (pythonExecutablePath: String, ytdlpExecutablePath: String) {
        let settings = try fetchDefaultSettings()
        return (settings.pythonExecutablePath, settings.ytdlpExecutablePath)
    }

    func updateExecutablePaths(pythonExecutablePath: String, ytdlpExecutablePath: String) throws {
        let normalizedPythonPath = (pythonExecutablePath as NSString)
            .expandingTildeInPath
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedYTDLPPath = (ytdlpExecutablePath as NSString)
            .expandingTildeInPath
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedPythonPath.isEmpty == false else {
            throw RuntimeError.invalidConfiguration("Python executable path cannot be empty.")
        }
        guard normalizedYTDLPPath.isEmpty == false else {
            throw RuntimeError.invalidConfiguration("yt-dlp executable path cannot be empty.")
        }

        let runtimeConfig = YTDLPRuntimeConfig(
            pythonExecutablePath: normalizedPythonPath,
            ytdlpExecutablePath: normalizedYTDLPPath
        )
        try RuntimeValidator().validate(config: runtimeConfig)

        let settings = try fetchDefaultSettings()
        settings.pythonExecutablePath = normalizedPythonPath
        settings.ytdlpExecutablePath = normalizedYTDLPPath
        settings.updatedAt = .now
        try modelContext.save()

        reconfigureRuntime(with: runtimeConfig)
    }

    func resetExecutablePathsToDefault() throws {
        try updateExecutablePaths(
            pythonExecutablePath: AppSettings.defaultPythonExecutablePath,
            ytdlpExecutablePath: AppSettings.defaultYTDLPExecutablePath
        )
    }

    private func resolveDownloadDirectory() throws -> URL {
        if let settings = try? fetchDefaultSettings() {
            return URL(fileURLWithPath: settings.downloadDirectoryPath, isDirectory: true)
        }

        throw AddClipboardYouTubeToCurrentListError.missingDownloadDirectory
    }

    private func fetchDefaultSettings() throws -> AppSettings {
        let settingsKey = AppSettings.defaultKey
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == settingsKey }
        )
        guard let settings = try modelContext.fetch(descriptor).first else {
            throw RuntimeError.invalidConfiguration("Default app settings are missing.")
        }
        return settings
    }

    private func reconfigureRuntime(with config: YTDLPRuntimeConfig) {
        ytDLPClient = YTDLPProcessClient(runtimeConfig: config)
        downloadManager = DownloadManager(
            downloadRepository: downloadRepository,
            ytDLPClient: ytDLPClient
        )
    }

    private static func bootstrap(
        playlistRepository: PlaylistRepository,
        modelContext: ModelContext
    ) throws -> AppSettings {
        let appPathProvider = AppPathProvider()
        let defaultDirectory = try appPathProvider.defaultDownloadDirectory()
        let settingsKey = AppSettings.defaultKey
        let settingsDescriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == settingsKey }
        )

        let settings: AppSettings
        if let existing = try modelContext.fetch(settingsDescriptor).first {
            if existing.downloadDirectoryPath.isEmpty {
                existing.downloadDirectoryPath = defaultDirectory.path
                existing.updatedAt = .now
                try modelContext.save()
            }
            settings = existing
        } else {
            let created = AppSettings(downloadDirectoryPath: defaultDirectory.path)
            modelContext.insert(created)
            try modelContext.save()
            settings = created
        }

        if let currentList = try playlistRepository.fetch(id: CurrentList.id) {
            if currentList.name != CurrentList.name {
                currentList.name = CurrentList.name
                currentList.updatedAt = .now
                try playlistRepository.save(currentList)
            }
        } else {
            try playlistRepository.save(
                Playlist(
                    id: CurrentList.id,
                    name: CurrentList.name
                )
            )
        }

        let playlists = try playlistRepository.fetchAll()
        for playlist in playlists where playlist.id != CurrentList.id {
            try playlistRepository.delete(id: playlist.id)
        }

        return settings
    }
}
