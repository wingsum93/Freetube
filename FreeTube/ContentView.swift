import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appContainer: AppContainer
    @EnvironmentObject private var playbackCoordinator: PlaylistPlaybackCoordinator

    @Query private var currentListItems: [PlaylistItem]
    @Query(sort: [SortDescriptor(\DownloadJob.createdAt, order: .reverse)]) private var downloadJobs: [DownloadJob]

    @State private var feedbackMessage: String?
    @State private var isProcessingPaste = false
    @State private var playbackSpeed = 1.0

    init() {
        let currentListID = CurrentList.id
        _currentListItems = Query(
            filter: #Predicate<PlaylistItem> { $0.playlistID == currentListID },
            sort: [SortDescriptor(\PlaylistItem.position)]
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    controlsSection
                    queueSection
                    nowPlayingSection
                }
                .padding(24)

                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .padding(12)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(18)
            }
            .navigationTitle("FreeTube")
        }
        .onAppear {
            playbackCoordinator.playbackSpeed = playbackSpeed
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Playlist: \(CurrentList.name)")
                .font(.title2)
                .bold()

            Text("Paste a YouTube link from browser clipboard, auto-queue, auto-download, then play sequentially.")
                .foregroundStyle(.secondary)
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await pasteFromClipboard()
                }
            } label: {
                Label(isProcessingPaste ? "Adding..." : "Paste", systemImage: "doc.on.clipboard")
            }
            .disabled(isProcessingPaste)

            Button {
                playCurrentList()
            } label: {
                Label("Play", systemImage: "play.fill")
            }

            HStack(spacing: 8) {
                Text("Speed \(String(format: "%.1fx", playbackSpeed))")
                    .monospacedDigit()
                Slider(value: $playbackSpeed, in: 0.5...2.0, step: 0.1)
                    .frame(width: 200)
                    .onChange(of: playbackSpeed) { _, newValue in
                        playbackCoordinator.playbackSpeed = newValue
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Queue")
                .font(.headline)

            List(currentListItems, id: \.id) { item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .lineLimit(1)
                        Text(statusText(for: item))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(role: .destructive) {
                        Task {
                            await removeItem(item.id)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
            .frame(minHeight: 260)
        }
    }

    private var nowPlayingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Now Playing")
                .font(.headline)

            if let currentItem = playbackCoordinator.currentItem {
                Text(currentItem.title)
                Text(currentItem.fileURL.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Nothing is playing.")
                    .foregroundStyle(.secondary)
            }

            if let feedbackMessage, feedbackMessage.isEmpty == false {
                Text(feedbackMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statusText(for item: PlaylistItem) -> String {
        guard let jobID = item.downloadJobID else {
            return "Queued"
        }
        guard let job = downloadJobs.first(where: { $0.id == jobID }) else {
            return "Queued"
        }

        switch job.status {
        case .queued:
            return "Queued"
        case .preparing:
            return "Preparing"
        case .downloading:
            return "Downloading"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        case .failed:
            let suffix = job.errorMessage.flatMap { $0.isEmpty ? nil : ": \($0)" } ?? ""
            return "Failed\(suffix)"
        case .cancelled:
            return "Cancelled"
        }
    }

    private func pasteFromClipboard() async {
        isProcessingPaste = true
        defer { isProcessingPaste = false }

        do {
            _ = try await appContainer.addClipboardYouTubeLink()
            feedbackMessage = "Link added to \(CurrentList.name). Download started."
        } catch {
            feedbackMessage = error.localizedDescription
        }
    }

    private func removeItem(_ itemID: UUID) async {
        do {
            try await appContainer.removeCurrentListItem(itemID: itemID)
            feedbackMessage = "Item removed."
        } catch {
            feedbackMessage = "Failed to remove item: \(error.localizedDescription)"
        }
    }

    private func playCurrentList() {
        let jobsByID = Dictionary(uniqueKeysWithValues: downloadJobs.map { ($0.id, $0) })
        let playable = currentListItems.compactMap { item -> PlaylistPlaybackItem? in
            guard let jobID = item.downloadJobID,
                  let job = jobsByID[jobID],
                  job.status == .completed else {
                return nil
            }

            let fileURL = URL(fileURLWithPath: job.outputPath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return nil
            }

            return PlaylistPlaybackItem(
                id: item.id,
                title: item.title,
                fileURL: fileURL
            )
        }

        playbackCoordinator.playbackSpeed = playbackSpeed
        playbackCoordinator.play(queue: playable)
        feedbackMessage = playable.isEmpty
            ? "No completed downloads in \(CurrentList.name)."
            : "Playing \(playable.count) item(s)."
    }
}

#Preview {
    let schema = Schema([
        AppSettings.self,
        VideoRecord.self,
        ChannelSubscription.self,
        Playlist.self,
        PlaylistItem.self,
        WatchHistoryEntry.self,
        DownloadJob.self,
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
    let appContainer = AppContainer(modelContainer: modelContainer)

    return ContentView()
        .modelContainer(modelContainer)
        .environmentObject(appContainer)
        .environmentObject(appContainer.playbackCoordinator)
}
