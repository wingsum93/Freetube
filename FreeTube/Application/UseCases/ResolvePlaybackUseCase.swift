import Foundation

struct ResolvePlaybackUseCase {
    let ytDLPClient: YTDLPClient

    func execute(videoURL: URL, format: StreamFormat = .bestCompatible) async throws -> PlaybackSource {
        let streamURL = try await ytDLPClient.resolveStreamURL(videoURL: videoURL, format: format)
        return .streamURL(streamURL)
    }
}
