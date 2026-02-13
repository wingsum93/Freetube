import Foundation
import Testing
@testable import FreeTube

struct QueueFeatureTests {

    @Test func addClipboardUseCaseRejectsInvalidURL() async throws {
        let playlistRepository = InMemoryPlaylistRepository()
        let videoRepository = InMemoryVideoRepository()
        let ytDLPClient = MockYTDLPClient()
        let downloadManager = MockDownloadManager()

        let useCase = AddClipboardYouTubeToCurrentListUseCase(
            playlistRepository: playlistRepository,
            videoRepository: videoRepository,
            ytDLPClient: ytDLPClient,
            downloadManager: downloadManager,
            clipboardStringProvider: { "not-a-url" },
            downloadDirectoryProvider: { URL(fileURLWithPath: "/tmp", isDirectory: true) }
        )

        await #expect(throws: AddClipboardYouTubeToCurrentListError.invalidURL) {
            _ = try await useCase.execute()
        }
        #expect(playlistRepository.items.isEmpty)
        #expect(downloadManager.enqueueRequests.isEmpty)
    }

    @Test func addClipboardUseCaseCreatesQueueItemAndEnqueuesDownload() async throws {
        let playlistRepository = InMemoryPlaylistRepository()
        let videoRepository = InMemoryVideoRepository()
        let ytDLPClient = MockYTDLPClient(
            metadata: VideoMetadataDTO(
                id: "abc123",
                title: "Demo Title",
                uploader: "Demo Uploader",
                thumbnail: nil,
                duration: 10,
                webpageURL: "https://www.youtube.com/watch?v=abc123"
            )
        )
        let downloadManager = MockDownloadManager()

        let useCase = AddClipboardYouTubeToCurrentListUseCase(
            playlistRepository: playlistRepository,
            videoRepository: videoRepository,
            ytDLPClient: ytDLPClient,
            downloadManager: downloadManager,
            clipboardStringProvider: { "https://www.youtube.com/watch?v=abc123" },
            downloadDirectoryProvider: { URL(fileURLWithPath: "/tmp", isDirectory: true) }
        )

        let itemID = try await useCase.execute()
        let fetchedItem = try playlistRepository.fetchItem(id: itemID)
        let createdItem = try #require(fetchedItem)

        #expect(createdItem.title == "Demo Title")
        #expect(createdItem.downloadJobID == downloadManager.enqueuedJobID)
        #expect(createdItem.sourceURLString == "https://www.youtube.com/watch?v=abc123")
        #expect(downloadManager.enqueueRequests.count == 1)
        #expect(videoRepository.recordsByID["abc123"]?.title == "Demo Title")
    }

    @Test func downloadManagerCancelQueuedJobMarksCancelled() async throws {
        let repository = InMemoryDownloadRepository()
        let client = BlockingYTDLPClient()
        let manager = DownloadManager(downloadRepository: repository, ytDLPClient: client)

        let firstRequest = DownloadRequest(
            sourceURL: URL(string: "https://www.youtube.com/watch?v=first")!,
            title: "first",
            preset: .video720pMP4,
            outputDirectory: URL(fileURLWithPath: "/tmp", isDirectory: true)
        )
        let secondRequest = DownloadRequest(
            sourceURL: URL(string: "https://www.youtube.com/watch?v=second")!,
            title: "second",
            preset: .video720pMP4,
            outputDirectory: URL(fileURLWithPath: "/tmp", isDirectory: true)
        )

        let firstJobID = try await manager.enqueue(firstRequest)
        let secondJobID = try await manager.enqueue(secondRequest)

        try await waitUntil {
            (try? repository.fetch(jobID: firstJobID)?.status) == .downloading
        }

        await manager.cancel(jobID: secondJobID)

        try await waitUntil {
            (try? repository.fetch(jobID: secondJobID)?.status) == .cancelled
        }

        await manager.cancel(jobID: firstJobID)
    }

    @Test func downloadManagerCancelActiveJobMarksCancelled() async throws {
        let repository = InMemoryDownloadRepository()
        let client = BlockingYTDLPClient()
        let manager = DownloadManager(downloadRepository: repository, ytDLPClient: client)

        let request = DownloadRequest(
            sourceURL: URL(string: "https://www.youtube.com/watch?v=active")!,
            title: "active",
            preset: .video720pMP4,
            outputDirectory: URL(fileURLWithPath: "/tmp", isDirectory: true)
        )

        let jobID = try await manager.enqueue(request)

        try await waitUntil {
            (try? repository.fetch(jobID: jobID)?.status) == .downloading
        }

        await manager.cancel(jobID: jobID)

        try await waitUntil {
            (try? repository.fetch(jobID: jobID)?.status) == .cancelled
        }
    }
}

private struct MockYTDLPClient: YTDLPClient {
    var metadata: VideoMetadataDTO = VideoMetadataDTO(
        id: "default",
        title: "default",
        uploader: nil,
        thumbnail: nil,
        duration: nil,
        webpageURL: "https://www.youtube.com/watch?v=default"
    )

    func fetchVideoMetadata(url: URL) async throws -> VideoMetadataDTO {
        metadata
    }

    func resolveStreamURL(videoURL: URL, format: StreamFormat) async throws -> URL {
        videoURL
    }

    func download(request: DownloadRequest) async throws -> URL {
        request.outputDirectory.appendingPathComponent("mock.mp4")
    }
}

private final class MockDownloadManager: DownloadManaging {
    var enqueuedJobID = UUID()
    var enqueueRequests: [DownloadRequest] = []

    func enqueue(_ request: DownloadRequest) async throws -> UUID {
        enqueueRequests.append(request)
        return enqueuedJobID
    }

    func cancel(jobID: UUID) async {}
}

private final class InMemoryPlaylistRepository: PlaylistRepository {
    var playlistsByID: [UUID: Playlist] = [:]
    var items: [PlaylistItem] = []

    func save(_ playlist: Playlist) throws {
        playlistsByID[playlist.id] = playlist
    }

    func fetch(id: UUID) throws -> Playlist? {
        playlistsByID[id]
    }

    func fetchAll() throws -> [Playlist] {
        playlistsByID.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    func delete(id: UUID) throws {
        playlistsByID.removeValue(forKey: id)
        items.removeAll { $0.playlistID == id }
    }

    func addItem(_ item: PlaylistItem) throws {
        items.append(item)
    }

    func fetchItem(id: UUID) throws -> PlaylistItem? {
        items.first { $0.id == id }
    }

    func fetchItems(playlistID: UUID) throws -> [PlaylistItem] {
        items
            .filter { $0.playlistID == playlistID }
            .sorted { $0.position < $1.position }
    }

    func updateItemDownloadJobID(itemID: UUID, downloadJobID: UUID?) throws {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else {
            return
        }
        items[index].downloadJobID = downloadJobID
    }

    func removeItem(id: UUID) throws {
        items.removeAll { $0.id == id }
    }
}

private final class InMemoryVideoRepository: VideoRepository {
    var recordsByID: [String: VideoRecord] = [:]

    func upsert(_ record: VideoRecord) throws {
        recordsByID[record.videoID] = record
    }

    func fetch(videoID: String) throws -> VideoRecord? {
        recordsByID[videoID]
    }

    func fetchAll() throws -> [VideoRecord] {
        recordsByID.values.sorted { $0.updatedAt > $1.updatedAt }
    }
}

private final class InMemoryDownloadRepository: DownloadRepository {
    private var jobsByID: [UUID: DownloadJob] = [:]

    func save(_ job: DownloadJob) throws {
        jobsByID[job.id] = job
    }

    func fetch(jobID: UUID) throws -> DownloadJob? {
        jobsByID[jobID]
    }

    func fetchAll() throws -> [DownloadJob] {
        jobsByID.values.sorted { $0.createdAt > $1.createdAt }
    }

    func updateStatus(jobID: UUID, status: DownloadStatus, progress: Double?, errorMessage: String?) throws {
        guard let job = jobsByID[jobID] else { return }
        job.status = status
        if let progress {
            job.progress = progress
        }
        job.errorMessage = errorMessage
        job.updatedAt = .now
    }

    func updateOutputPath(jobID: UUID, outputPath: String) throws {
        guard let job = jobsByID[jobID] else { return }
        job.outputPath = outputPath
        job.updatedAt = .now
    }

    func delete(jobID: UUID) throws {
        jobsByID.removeValue(forKey: jobID)
    }
}

private struct BlockingYTDLPClient: YTDLPClient {
    func fetchVideoMetadata(url: URL) async throws -> VideoMetadataDTO {
        VideoMetadataDTO(
            id: "blocking",
            title: "blocking",
            uploader: nil,
            thumbnail: nil,
            duration: nil,
            webpageURL: url.absoluteString
        )
    }

    func resolveStreamURL(videoURL: URL, format: StreamFormat) async throws -> URL {
        videoURL
    }

    func download(request: DownloadRequest) async throws -> URL {
        try await Task.sleep(for: .seconds(10))
        return request.outputDirectory.appendingPathComponent("blocking.mp4")
    }
}

private func waitUntil(
    timeout: Duration = .seconds(5),
    condition: @escaping () -> Bool
) async throws {
    let start = ContinuousClock.now
    let clock = ContinuousClock()

    while condition() == false {
        if clock.now - start > timeout {
            throw RuntimeError.invalidConfiguration("Timed out waiting for condition")
        }
        try await Task.sleep(for: .milliseconds(50))
    }
}
