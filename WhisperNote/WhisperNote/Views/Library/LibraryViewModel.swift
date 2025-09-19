import Foundation
import SwiftUI

enum SortOption {
    case date
    case duration
    case size
}

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var recordings: [Recording] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fileManager = RecordingFileManager.shared
    private var sortOption: SortOption = .date

    init() {
        loadRecordings()
    }

    func loadRecordings() {
        recordings = fileManager.loadAllRecordings()
        sortRecordings()
    }

    func refreshRecordings() async {
        isLoading = true
        await MainActor.run {
            loadRecordings()
            isLoading = false
        }
    }

    func sortBy(_ option: SortOption) {
        sortOption = option
        sortRecordings()
    }

    private func sortRecordings() {
        switch sortOption {
        case .date:
            recordings.sort { $0.recordedAt > $1.recordedAt }
        case .duration:
            recordings.sort { $0.duration > $1.duration }
        case .size:
            recordings.sort { $0.fileSize > $1.fileSize }
        }
    }

    func deleteRecording(_ recording: Recording) {
        do {
            try fileManager.deleteRecording(recording)
            recordings.removeAll { $0.id == recording.id }
        } catch {
            errorMessage = "Failed to delete recording: \(error.localizedDescription)"
        }
    }

    func transcribeRecording(_ recording: Recording) {
        Task {
            do {
                _ = try await TranscriptionService.shared.transcribeRecording(recording)
                await MainActor.run {
                    loadRecordings() // Reload to show updated status
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Transcription failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func shareRecording(_ recording: Recording, audioOnly: Bool = false) {
        var itemsToShare: [Any] = []

        // Add audio file
        let audioURL = URL(fileURLWithPath: recording.audioPath)
        if FileManager.default.fileExists(atPath: audioURL.path) {
            itemsToShare.append(audioURL)
        }

        // Add transcript if available and not audio-only
        if !audioOnly, let transcriptPath = recording.transcriptPath {
            let transcriptURL = URL(fileURLWithPath: transcriptPath)
            if FileManager.default.fileExists(atPath: transcriptURL.path) {
                itemsToShare.append(transcriptURL)
            }
        }

        guard !itemsToShare.isEmpty else {
            errorMessage = "No files available to share"
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {

            // For iPad
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                           y: rootViewController.view.bounds.midY,
                                           width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            rootViewController.present(activityViewController, animated: true)
        }
    }
}