import Foundation
import SwiftData

@Model
final class PlaylistItem {
    @Attribute(.unique) var id: UUID
    var playlistID: UUID
    var videoID: String
    var title: String
    var position: Int
    var addedAt: Date

    init(
        id: UUID = UUID(),
        playlistID: UUID,
        videoID: String,
        title: String,
        position: Int,
        addedAt: Date = .now
    ) {
        self.id = id
        self.playlistID = playlistID
        self.videoID = videoID
        self.title = title
        self.position = position
        self.addedAt = addedAt
    }
}
