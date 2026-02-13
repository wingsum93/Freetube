import Foundation
import SwiftData

final class SwiftDataVideoRepository: VideoRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func upsert(_ record: VideoRecord) throws {
        let videoID = record.videoID
        let descriptor = FetchDescriptor<VideoRecord>(predicate: #Predicate { $0.videoID == videoID })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.title = record.title
            existing.uploader = record.uploader
            existing.thumbnailURLString = record.thumbnailURLString
            existing.durationSeconds = record.durationSeconds
            existing.sourceURLString = record.sourceURLString
            existing.updatedAt = .now
        } else {
            modelContext.insert(record)
        }
        try modelContext.save()
    }

    func fetch(videoID: String) throws -> VideoRecord? {
        let descriptor = FetchDescriptor<VideoRecord>(predicate: #Predicate { $0.videoID == videoID })
        return try modelContext.fetch(descriptor).first
    }

    func fetchAll() throws -> [VideoRecord] {
        let descriptor = FetchDescriptor<VideoRecord>(sortBy: [SortDescriptor(\VideoRecord.updatedAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
}
