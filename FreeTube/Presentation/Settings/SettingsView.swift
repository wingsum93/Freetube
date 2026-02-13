import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Runtime") {
                Text("Runtime configuration functions are pending definition.")
            }

            Section("Downloads") {
                Text("Download behavior settings are pending definition.")
            }

            Section("Playback") {
                Text("Playback preferences are pending definition.")
            }
        }
        .navigationTitle("Settings")
        .frame(minWidth: 480, minHeight: 320)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
