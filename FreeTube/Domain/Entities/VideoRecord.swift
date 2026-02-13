import Foundation
import SwiftData

@Model
final class VideoRecord {
    @Attribute(.unique) var videoID: String
    var title: String
    var uploader: String?
    var thumbnailURLString: String?
    var durationSeconds: Double?
    var sourceURLString: String
    var createdAt: Date
    var updatedAt: Date

    init(
        videoID: String,
        title: String,
        uploader: String? = nil,
        thumbnailURLString: String? = nil,
        durationSeconds: Double? = nil,
        sourceURLString: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.videoID = videoID
        self.title = title
        self.uploader = uploader
        self.thumbnailURLString = thumbnailURLString
        self.durationSeconds = durationSeconds
        self.sourceURLString = sourceURLString
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
