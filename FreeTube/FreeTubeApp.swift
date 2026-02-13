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
    var sharedModelContainer: ModelContainer = {
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
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
