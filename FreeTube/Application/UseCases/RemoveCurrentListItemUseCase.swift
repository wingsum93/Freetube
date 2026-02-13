import Foundation

struct RemoveCurrentListItemUseCase {
    let playlistRepository: PlaylistRepository
    let downloadRepository: DownloadRepository
    let downloadManager: DownloadManaging
    let fileManager: FileManager = .default

    func execute(itemID: UUID) async throws {
        guard let item = try playlistRepository.fetchItem(id: itemID) else {
            return
        }

        if let jobID = item.downloadJobID {
            if let job = try downloadRepository.fetch(jobID: jobID) {
                switch job.status {
                case .queued, .preparing, .downloading, .paused:
                    await downloadManager.cancel(jobID: jobID)
                    try? removeFileIfPresent(at: job.outputPath)
                case .failed, .cancelled:
                    try? removeFileIfPresent(at: job.outputPath)
                case .completed:
                    break
                }
            }
            try? downloadRepository.delete(jobID: jobID)
        }

        try playlistRepository.removeItem(id: itemID)
    }

    private func removeFileIfPresent(at outputPath: String) throws {
        guard outputPath.isEmpty == false else {
            return
        }

        let fileURL = URL(fileURLWithPath: outputPath)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        try fileManager.removeItem(at: fileURL)
    }
}
