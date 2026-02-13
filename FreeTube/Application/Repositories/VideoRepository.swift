import Foundation

protocol VideoRepository {
    func upsert(_ record: VideoRecord) throws
    func fetch(videoID: String) throws -> VideoRecord?
    func fetchAll() throws -> [VideoRecord]
}
