import Foundation

enum AddClipboardYouTubeToCurrentListError: LocalizedError {
    case emptyClipboard
    case invalidURL
    case unsupportedHost
    case missingDownloadDirectory

    var errorDescription: String? {
        switch self {
        case .emptyClipboard:
            return "Clipboard is empty."
        case .invalidURL:
            return "Clipboard does not contain a valid URL."
        case .unsupportedHost:
            return "Only YouTube links are supported."
        case .missingDownloadDirectory:
            return "Download directory is not configured."
        }
    }
}

struct AddClipboardYouTubeToCurrentListUseCase {
    let playlistRepository: PlaylistRepository
    let videoRepository: VideoRepository
    let ytDLPClient: YTDLPClient
    let downloadManager: DownloadManaging
    let clipboardStringProvider: () -> String?
    let downloadDirectoryProvider: () throws -> URL

    @discardableResult
    func execute() async throws -> UUID {
        guard let clipboardValue = clipboardStringProvider()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboardValue.isEmpty else {
            throw AddClipboardYouTubeToCurrentListError.emptyClipboard
        }

        guard let inputURL = URL(string: clipboardValue) else {
            throw AddClipboardYouTubeToCurrentListError.invalidURL
        }
        try validateYouTubeHost(url: inputURL)

        let metadata = try await ytDLPClient.fetchVideoMetadata(url: inputURL)
        let sourceURL = URL(string: metadata.webpageURL ?? inputURL.absoluteString) ?? inputURL
        let title = metadata.title.isEmpty ? sourceURL.absoluteString : metadata.title

        try videoRepository.upsert(
            VideoRecord(
                videoID: metadata.id,
                title: title,
                uploader: metadata.uploader,
                thumbnailURLString: metadata.thumbnail,
                durationSeconds: metadata.duration,
                sourceURLString: sourceURL.absoluteString
            )
        )

        let items = try playlistRepository.fetchItems(playlistID: CurrentList.id)
        let nextPosition = (items.last?.position ?? -1) + 1
        let item = PlaylistItem(
            playlistID: CurrentList.id,
            videoID: metadata.id,
            sourceURLString: sourceURL.absoluteString,
            title: title,
            position: nextPosition
        )
        try playlistRepository.addItem(item)

        let outputDirectory = try downloadDirectoryProvider()
        guard outputDirectory.path.isEmpty == false else {
            throw AddClipboardYouTubeToCurrentListError.missingDownloadDirectory
        }

        let jobID = try await downloadManager.enqueue(
            DownloadRequest(
                sourceURL: sourceURL,
                title: title,
                preset: .video720pMP4,
                outputDirectory: outputDirectory
            )
        )
        try playlistRepository.updateItemDownloadJobID(itemID: item.id, downloadJobID: jobID)

        return item.id
    }

    private func validateYouTubeHost(url: URL) throws {
        guard let host = url.host?.lowercased() else {
            throw AddClipboardYouTubeToCurrentListError.invalidURL
        }

        let isYouTubeHost = host == "youtube.com" || host.hasSuffix(".youtube.com")
        let isShortYouTubeHost = host == "youtu.be"
        guard isYouTubeHost || isShortYouTubeHost else {
            throw AddClipboardYouTubeToCurrentListError.unsupportedHost
        }
    }
}
