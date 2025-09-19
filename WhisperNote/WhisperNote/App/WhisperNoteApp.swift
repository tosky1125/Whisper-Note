import SwiftUI

@main
struct WhisperNoteApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                ModelDownloadView()
            }
        }
    }
}