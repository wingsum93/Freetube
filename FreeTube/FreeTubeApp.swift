//
//  FreeTubeApp.swift
//  FreeTube
//
//  Created by eric ho on 13/2/2026.
//

import SwiftUI
import SwiftData

@main
struct FreeTubeApp: App {
    private let sharedModelContainer: ModelContainer
    @StateObject private var appContainer: AppContainer

    init() {
        let modelContainer = Self.makeModelContainer()
        self.sharedModelContainer = modelContainer
        _appContainer = StateObject(wrappedValue: AppContainer(modelContainer: modelContainer))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appContainer)
                .environmentObject(appContainer.playbackCoordinator)
        }
        .modelContainer(sharedModelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            AppSettings.self,
            VideoRecord.self,
            ChannelSubscription.self,
            Playlist.self,
            PlaylistItem.self,
            WatchHistoryEntry.self,
            DownloadJob.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
