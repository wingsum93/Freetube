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

    let ytDLPClient: YTDLPClient
    let downloadManager: DownloadManager
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

    private func resolveDownloadDirectory() throws -> URL {
        let descriptor = FetchDescriptor<AppSettings>(predicate: #Predicate { $0.key == "default" })
        if let settings = try modelContext.fetch(descriptor).first {
            return URL(fileURLWithPath: settings.downloadDirectoryPath, isDirectory: true)
        }

        throw AddClipboardYouTubeToCurrentListError.missingDownloadDirectory
    }

    private static func bootstrap(
        playlistRepository: PlaylistRepository,
        modelContext: ModelContext
    ) throws -> AppSettings {
        let appPathProvider = AppPathProvider()
        let defaultDirectory = try appPathProvider.defaultDownloadDirectory()
        let settingsDescriptor = FetchDescriptor<AppSettings>(predicate: #Predicate { $0.key == "default" })

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
