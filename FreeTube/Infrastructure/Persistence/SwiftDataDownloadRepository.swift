import Foundation
import SwiftData

final class SwiftDataDownloadRepository: DownloadRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ job: DownloadJob) throws {
        let jobID = job.id
        let descriptor = FetchDescriptor<DownloadJob>(predicate: #Predicate { $0.id == jobID })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.sourceURLString = job.sourceURLString
            existing.title = job.title
            existing.preset = job.preset
            existing.outputPath = job.outputPath
            existing.status = job.status
            existing.progress = job.progress
            existing.errorMessage = job.errorMessage
            existing.updatedAt = .now
        } else {
            modelContext.insert(job)
        }
        try modelContext.save()
    }

    func fetch(jobID: UUID) throws -> DownloadJob? {
        let descriptor = FetchDescriptor<DownloadJob>(predicate: #Predicate { $0.id == jobID })
        return try modelContext.fetch(descriptor).first
    }

    func fetchAll() throws -> [DownloadJob] {
        let descriptor = FetchDescriptor<DownloadJob>(sortBy: [SortDescriptor(\DownloadJob.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func updateStatus(jobID: UUID, status: DownloadStatus, progress: Double?, errorMessage: String?) throws {
        let descriptor = FetchDescriptor<DownloadJob>(predicate: #Predicate { $0.id == jobID })
        guard let job = try modelContext.fetch(descriptor).first else {
            return
        }

        job.status = status
        if let progress {
            job.progress = progress
        }
        job.errorMessage = errorMessage
        job.updatedAt = .now
        try modelContext.save()
    }

    func updateOutputPath(jobID: UUID, outputPath: String) throws {
        let descriptor = FetchDescriptor<DownloadJob>(predicate: #Predicate { $0.id == jobID })
        guard let job = try modelContext.fetch(descriptor).first else {
            return
        }

        job.outputPath = outputPath
        job.updatedAt = .now
        try modelContext.save()
    }

    func delete(jobID: UUID) throws {
        let descriptor = FetchDescriptor<DownloadJob>(predicate: #Predicate { $0.id == jobID })
        guard let job = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(job)
        try modelContext.save()
    }
}
