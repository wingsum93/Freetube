import Foundation

actor DownloadManager: DownloadManaging {
    private struct PendingDownload {
        let request: DownloadRequest
        let jobID: UUID
    }

    private let downloadRepository: DownloadRepository
    private let ytDLPClient: YTDLPClient
    private var queue: [PendingDownload] = []
    private var isProcessing = false
    private var activeJobID: UUID?
    private var activeDownloadTask: Task<Void, Never>?

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
                outputPath: "",
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

    func cancel(jobID: UUID) async {
        if let queueIndex = queue.firstIndex(where: { $0.jobID == jobID }) {
            queue.remove(at: queueIndex)
            try? await MainActor.run {
                try downloadRepository.updateStatus(
                    jobID: jobID,
                    status: .cancelled,
                    progress: nil,
                    errorMessage: nil
                )
            }
            updatesContinuation.yield(.cancelled(jobID: jobID))
            return
        }

        guard activeJobID == jobID else {
            return
        }
        activeDownloadTask?.cancel()
    }

    private func processNextIfNeeded() async {
        guard !isProcessing, let next = queue.first else { return }

        isProcessing = true
        queue.removeFirst()
        activeJobID = next.jobID

        let task = Task { await self.processDownload(next) }
        activeDownloadTask = task
        await task.value

        activeDownloadTask = nil
        activeJobID = nil
        isProcessing = false
        if !queue.isEmpty {
            await processNextIfNeeded()
        }
    }

    private func processDownload(_ pending: PendingDownload) async {
        do {
            try await MainActor.run {
                try downloadRepository.updateStatus(
                    jobID: pending.jobID,
                    status: .downloading,
                    progress: 0,
                    errorMessage: nil
                )
            }
            updatesContinuation.yield(.started(jobID: pending.jobID))

            let outputURL = try await ytDLPClient.download(request: pending.request)
            try await MainActor.run {
                try downloadRepository.updateOutputPath(
                    jobID: pending.jobID,
                    outputPath: outputURL.path
                )
                try downloadRepository.updateStatus(
                    jobID: pending.jobID,
                    status: .completed,
                    progress: 1,
                    errorMessage: nil
                )
            }
            updatesContinuation.yield(.completed(jobID: pending.jobID, fileURL: outputURL))
        } catch is CancellationError {
            try? await MainActor.run {
                try downloadRepository.updateStatus(
                    jobID: pending.jobID,
                    status: .cancelled,
                    progress: nil,
                    errorMessage: nil
                )
            }
            updatesContinuation.yield(.cancelled(jobID: pending.jobID))
        } catch {
            try? await MainActor.run {
                try downloadRepository.updateStatus(
                    jobID: pending.jobID,
                    status: .failed,
                    progress: nil,
                    errorMessage: error.localizedDescription
                )
            }
            updatesContinuation.yield(.failed(jobID: pending.jobID, reason: error.localizedDescription))
        }
    }
}
