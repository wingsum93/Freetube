import Foundation

protocol DownloadRepository {
    func save(_ job: DownloadJob) throws
    func fetch(jobID: UUID) throws -> DownloadJob?
    func fetchAll() throws -> [DownloadJob]
    func updateStatus(jobID: UUID, status: DownloadStatus, progress: Double?, errorMessage: String?) throws
}
