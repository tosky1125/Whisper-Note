import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic.circle.fill")
                }

            LibraryViewEnhanced()
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




#Preview {
    ContentView()
}