import Foundation

enum DownloadEvent: Sendable {
    case queued(jobID: UUID)
    case started(jobID: UUID)
    case completed(jobID: UUID, fileURL: URL)
    case failed(jobID: UUID, reason: String)
    case cancelled(jobID: UUID)
}
