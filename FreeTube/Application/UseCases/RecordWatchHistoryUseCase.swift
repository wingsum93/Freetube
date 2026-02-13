import Foundation

struct RecordWatchHistoryUseCase {
    let historyRepository: HistoryRepository

    func execute(
        videoID: String,
        title: String,
        sourceURL: URL,
        progressSeconds: Double,
        durationSeconds: Double?
    ) throws {
        let entry = WatchHistoryEntry(
            videoID: videoID,
            title: title,
            sourceURLString: sourceURL.absoluteString,
            watchedAt: .now,
            playbackProgressSeconds: progressSeconds,
            durationSeconds: durationSeconds
        )
        try historyRepository.add(entry)
    }
}
