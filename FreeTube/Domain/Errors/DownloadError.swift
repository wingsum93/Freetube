import Foundation

enum DownloadError: Error {
    case enqueueFailed(String)
    case processFailed(String)
    case cancelled
}
