import Foundation
import SwiftData

enum DownloadStatus: String, Codable, CaseIterable, Sendable {
    case queued
    case preparing
    case downloading
    case paused
    case completed
    case failed
    case cancelled
}

@Model
final class DownloadJob {
    @Attribute(.unique) var id: UUID
    var sourceURLString: String
    var title: String
    var presetRawValue: String
    var outputPath: String
    var statusRawValue: String
    var progress: Double
    var errorMessage: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        sourceURLString: String,
        title: String,
        preset: DownloadPreset,
        outputPath: String,
        status: DownloadStatus = .queued,
        progress: Double = 0,
        errorMessage: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.sourceURLString = sourceURLString
        self.title = title
        self.presetRawValue = preset.rawValue
        self.outputPath = outputPath
        self.statusRawValue = status.rawValue
        self.progress = progress
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var preset: DownloadPreset {
        get { DownloadPreset(rawValue: presetRawValue) ?? .video720pMP4 }
        set { presetRawValue = newValue.rawValue }
    }

    var status: DownloadStatus {
        get { DownloadStatus(rawValue: statusRawValue) ?? .queued }
        set { statusRawValue = newValue.rawValue }
    }
}
