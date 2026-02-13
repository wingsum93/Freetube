import Foundation
import SwiftData

final class SwiftDataHistoryRepository: HistoryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func add(_ entry: WatchHistoryEntry) throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func recent(limit: Int) throws -> [WatchHistoryEntry] {
        var descriptor = FetchDescriptor<WatchHistoryEntry>(sortBy: [SortDescriptor(\WatchHistoryEntry.watchedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func clearAll() throws {
        let descriptor = FetchDescriptor<WatchHistoryEntry>()
        try modelContext.fetch(descriptor).forEach(modelContext.delete)
        try modelContext.save()
    }
}
