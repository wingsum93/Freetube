import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var appContainer: AppContainer

    @State private var pythonExecutablePath = ""
    @State private var ytdlpExecutablePath = ""
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section("Python Executable Path") {
                Text("Path")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Python executable path", text: $pythonExecutablePath)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    Button("Change") {
                        applyCurrentPaths()
                    }

                    Button("Reset") {
                        resetPathsToDefault()
                    }
                }
            }

            Section("yt-dlp Executable Path") {
                Text("Path")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("yt-dlp executable path", text: $ytdlpExecutablePath)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    Button("Change") {
                        applyCurrentPaths()
                    }

                    Button("Reset") {
                        resetPathsToDefault()
                    }
                }
            }

            Section("Message") {
                if errorMessage.isEmpty {
                    Text("No error.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Settings")
        .frame(minWidth: 480, minHeight: 320)
        .onAppear {
            loadExecutablePaths()
        }
    }

    private func loadExecutablePaths() {
        do {
            let paths = try appContainer.currentExecutablePaths()
            pythonExecutablePath = paths.pythonExecutablePath
            ytdlpExecutablePath = paths.ytdlpExecutablePath
        } catch {
            errorMessage = displayMessage(for: error)
        }
    }

    private func applyCurrentPaths() {
        errorMessage = ""
        do {
            try appContainer.updateExecutablePaths(
                pythonExecutablePath: pythonExecutablePath,
                ytdlpExecutablePath: ytdlpExecutablePath
            )
            let paths = try appContainer.currentExecutablePaths()
            pythonExecutablePath = paths.pythonExecutablePath
            ytdlpExecutablePath = paths.ytdlpExecutablePath
        } catch {
            errorMessage = displayMessage(for: error)
        }
    }

    private func resetPathsToDefault() {
        errorMessage = ""
        do {
            try appContainer.resetExecutablePathsToDefault()
            let paths = try appContainer.currentExecutablePaths()
            pythonExecutablePath = paths.pythonExecutablePath
            ytdlpExecutablePath = paths.ytdlpExecutablePath
        } catch {
            errorMessage = displayMessage(for: error)
        }
    }

    private func displayMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           description.isEmpty == false {
            return description
        }
        return error.localizedDescription
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

    NavigationStack {
        SettingsView()
            .environmentObject(appContainer)
    }
}
