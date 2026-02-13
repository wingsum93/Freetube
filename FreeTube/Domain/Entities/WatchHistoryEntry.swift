import Foundation
import SwiftData

@Model
final class WatchHistoryEntry {
    @Attribute(.unique) var id: UUID
    var videoID: String
    var title: String
    var sourceURLString: String
    var watchedAt: Date
    var playbackProgressSeconds: Double
    var durationSeconds: Double?

    init(
        id: UUID = UUID(),
        videoID: String,
        title: String,
        sourceURLString: String,
        watchedAt: Date = .now,
        playbackProgressSeconds: Double = 0,
        durationSeconds: Double? = nil
    ) {
        self.id = id
        self.videoID = videoID
        self.title = title
        self.sourceURLString = sourceURLString
        self.watchedAt = watchedAt
        self.playbackProgressSeconds = playbackProgressSeconds
        self.durationSeconds = durationSeconds
    }
}
