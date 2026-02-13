import Foundation

enum PlaybackSource: Sendable, Equatable {
    case streamURL(URL)
    case localFile(URL)
}
