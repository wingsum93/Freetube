import Foundation

enum DownloadPreset: String, Codable, CaseIterable, Sendable {
    case video720pMP4 = "video_720p_mp4"
    case video1080pMP4 = "video_1080p_mp4"
    case audioM4A = "audio_m4a"
    case audioMP3 = "audio_mp3"
}
