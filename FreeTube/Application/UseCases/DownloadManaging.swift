import Foundation

protocol DownloadManaging {
    @discardableResult
    func enqueue(_ request: DownloadRequest) async throws -> UUID
    func cancel(jobID: UUID) async
}
