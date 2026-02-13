import Foundation

actor DownloadManager {
    private struct PendingDownload {
        let request: DownloadRequest
        let jobID: UUID
    }

    private let downloadRepository: DownloadRepository
    private let ytDLPClient: YTDLPClient
    private var queue: [PendingDownload] = []
    private var isProcessing = false

    private let updatesStream: AsyncStream<DownloadEvent>
    private let updatesContinuation: AsyncStream<DownloadEvent>.Continuation

    init(downloadRepository: DownloadRepository, ytDLPClient: YTDLPClient) {
        self.downloadRepository = downloadRepository
        self.ytDLPClient = ytDLPClient

        var continuation: AsyncStream<DownloadEvent>.Continuation?
        self.updatesStream = AsyncStream { streamContinuation in
            continuation = streamContinuation
        }
        self.updatesContinuation = continuation!
    }

    func updates() -> AsyncStream<DownloadEvent> {
        updatesStream
    }

    @discardableResult
    func enqueue(_ request: DownloadRequest) async throws -> UUID {
        let jobID = UUID()

        try await MainActor.run {
            let job = DownloadJob(
                id: jobID,
                sourceURLString: request.sourceURL.absoluteString,
                title: request.title,
                preset: request.preset,
                outputPath: request.outputDirectory.path,
                status: .queued,
                progress: 0
            )
            try downloadRepository.save(job)
        }
        queue.append(PendingDownload(request: request, jobID: jobID))
        updatesContinuation.yield(.queued(jobID: jobID))

        Task {
            await self.processNextIfNeeded()
        }

        return jobID
    }

    private func processNextIfNeeded() async {
        guard !isProcessing, let next = queue.first else { return }

        isProcessing = true
        queue.removeFirst()

        do {
            try await MainActor.run {
                try downloadRepository.updateStatus(
                    jobID: next.jobID,
                    status: .downloading,
                    progress: 0,
                    errorMessage: nil
                )
            }
            updatesContinuation.yield(.started(jobID: next.jobID))

            let outputURL = try await ytDLPClient.download(request: next.request)
            try await MainActor.run {
                try downloadRepository.updateStatus(
                    jobID: next.jobID,
                    status: .completed,
                    progress: 1,
                    errorMessage: nil
                )
            }
            updatesContinuation.yield(.completed(jobID: next.jobID, fileURL: outputURL))
        } catch {
            try? await MainActor.run {
                try downloadRepository.updateStatus(
                    jobID: next.jobID,
                    status: .failed,
                    progress: nil,
                    errorMessage: error.localizedDescription
                )
            }
            updatesContinuation.yield(.failed(jobID: next.jobID, reason: error.localizedDescription))
        }

        isProcessing = false
        if !queue.isEmpty {
            await processNextIfNeeded()
        }
    }
}
