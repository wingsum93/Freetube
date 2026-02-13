import Foundation
import SwiftData

final class SwiftDataPlaylistRepository: PlaylistRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ playlist: Playlist) throws {
        let playlistID = playlist.id
        let descriptor = FetchDescriptor<Playlist>(predicate: #Predicate { $0.id == playlistID })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.name = playlist.name
            existing.updatedAt = .now
        } else {
            modelContext.insert(playlist)
        }
        try modelContext.save()
    }

    func fetch(id: UUID) throws -> Playlist? {
        let descriptor = FetchDescriptor<Playlist>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }

    func fetchAll() throws -> [Playlist] {
        let descriptor = FetchDescriptor<Playlist>(sortBy: [SortDescriptor(\Playlist.updatedAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<Playlist>(predicate: #Predicate { $0.id == id })
        if let playlist = try modelContext.fetch(descriptor).first {
            let items = try fetchItems(playlistID: id)
            items.forEach(modelContext.delete)
            modelContext.delete(playlist)
            try modelContext.save()
        }
    }

    func addItem(_ item: PlaylistItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }

    func fetchItems(playlistID: UUID) throws -> [PlaylistItem] {
        let descriptor = FetchDescriptor<PlaylistItem>(
            predicate: #Predicate { $0.playlistID == playlistID },
            sortBy: [SortDescriptor(\PlaylistItem.position)]
        )
        return try modelContext.fetch(descriptor)
    }

    func removeItem(id: UUID) throws {
        let descriptor = FetchDescriptor<PlaylistItem>(predicate: #Predicate { $0.id == id })
        if let item = try modelContext.fetch(descriptor).first {
            modelContext.delete(item)
            try modelContext.save()
        }
    }
}
