import Foundation

protocol HistoryRepository {
    func add(_ entry: WatchHistoryEntry) throws
    func recent(limit: Int) throws -> [WatchHistoryEntry]
    func clearAll() throws
}
