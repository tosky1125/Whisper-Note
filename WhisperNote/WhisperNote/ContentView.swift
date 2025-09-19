import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic.circle.fill")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "folder.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct RecordingView: View {
    var body: some View {
        Text("Recording View")
    }
}

struct LibraryView: View {
    var body: some View {
        Text("Library View")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings View")
    }
}

#Preview {
    ContentView()
}