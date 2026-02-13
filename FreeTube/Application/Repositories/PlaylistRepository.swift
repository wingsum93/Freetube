import Foundation

protocol PlaylistRepository {
    func save(_ playlist: Playlist) throws
    func fetch(id: UUID) throws -> Playlist?
    func fetchAll() throws -> [Playlist]
    func delete(id: UUID) throws

    func addItem(_ item: PlaylistItem) throws
    func fetchItem(id: UUID) throws -> PlaylistItem?
    func fetchItems(playlistID: UUID) throws -> [PlaylistItem]
    func updateItemDownloadJobID(itemID: UUID, downloadJobID: UUID?) throws
    func removeItem(id: UUID) throws
}
