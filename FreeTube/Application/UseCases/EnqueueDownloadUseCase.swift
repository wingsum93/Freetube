import Foundation

struct EnqueueDownloadUseCase {
    let downloadManager: DownloadManaging

    @discardableResult
    func execute(request: DownloadRequest) async throws -> UUID {
        try await downloadManager.enqueue(request)
    }
}
