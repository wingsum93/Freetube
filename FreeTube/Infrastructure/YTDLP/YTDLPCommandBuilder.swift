import Foundation

struct YTDLPCommandBuilder {
    func metadataArguments(videoURL: URL) -> [String] {
        ["--dump-single-json", "--no-warnings", videoURL.absoluteString]
    }

    func streamURLArguments(videoURL: URL, format: StreamFormat) -> [String] {
        ["-g", "-f", formatSelector(for: format), "--no-warnings", videoURL.absoluteString]
    }

    func downloadArguments(request: DownloadRequest, outputFile: URL) -> [String] {
        ["-f", formatSelector(for: .preset(request.preset)), "-o", outputFile.path, request.sourceURL.absoluteString]
    }

    func outputFileURL(for request: DownloadRequest) -> URL {
        let safeTitle = sanitizeFileName(request.title)
        let fileExtension = fileExtensionForPreset(request.preset)
        return request.outputDirectory.appendingPathComponent("\(safeTitle).\(fileExtension)")
    }

    private func formatSelector(for format: StreamFormat) -> String {
        switch format {
        case .bestCompatible:
            return "bv*+ba/b"
        case .audioOnly:
            return "bestaudio"
        case .preset(let preset):
            switch preset {
            case .video720pMP4:
                return "bestvideo[height<=720]+bestaudio/best[height<=720]"
            case .video1080pMP4:
                return "bestvideo[height<=1080]+bestaudio/best[height<=1080]"
            case .audioM4A:
                return "bestaudio[ext=m4a]/bestaudio"
            case .audioMP3:
                return "bestaudio"
            }
        case .custom(let selector):
            return selector
        }
    }

    private func fileExtensionForPreset(_ preset: DownloadPreset) -> String {
        switch preset {
        case .video720pMP4, .video1080pMP4:
            return "mp4"
        case .audioM4A:
            return "m4a"
        case .audioMP3:
            return "mp3"
        }
    }

    private func sanitizeFileName(_ input: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return input
            .components(separatedBy: invalid)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
            .prefix(120)
            .description
    }
}
