import AVFoundation
import Combine
import Foundation

struct PlaylistPlaybackItem: Identifiable, Sendable {
    let id: UUID
    let title: String
    let fileURL: URL
}

@MainActor
final class PlaylistPlaybackCoordinator: ObservableObject {
    @Published private(set) var currentItem: PlaylistPlaybackItem?
    @Published private(set) var isPlaying = false
    @Published var playbackSpeed: Double = 1.0 {
        didSet { applyRate() }
    }

    private let player = AVPlayer()
    private var queue: [PlaylistPlaybackItem] = []
    private var currentIndex: Int?
    private var endObserver: NSObjectProtocol?

    init() {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard notification.object as AnyObject? === self.player.currentItem else { return }
            self.advance()
        }
    }

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    func play(queue: [PlaylistPlaybackItem]) {
        guard queue.isEmpty == false else {
            stop()
            return
        }

        self.queue = queue
        currentIndex = 0
        startCurrent()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        queue = []
        currentIndex = nil
        currentItem = nil
        isPlaying = false
    }

    private func startCurrent() {
        guard let currentIndex, queue.indices.contains(currentIndex) else {
            stop()
            return
        }

        let item = queue[currentIndex]
        currentItem = item
        let playerItem = AVPlayerItem(url: item.fileURL)
        player.replaceCurrentItem(with: playerItem)
        player.play()
        isPlaying = true
        applyRate()
    }

    private func advance() {
        guard let currentIndex else { return }

        let nextIndex = currentIndex + 1
        guard queue.indices.contains(nextIndex) else {
            stop()
            return
        }

        self.currentIndex = nextIndex
        startCurrent()
    }

    private func applyRate() {
        guard playbackSpeed >= 0.5, playbackSpeed <= 2.0 else {
            playbackSpeed = min(max(playbackSpeed, 0.5), 2.0)
            return
        }

        guard isPlaying else { return }
        player.rate = Float(playbackSpeed)
    }
}
