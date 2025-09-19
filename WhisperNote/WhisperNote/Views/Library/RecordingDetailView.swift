import SwiftUI
import AVFoundation

struct RecordingDetailView: View {
    @State var recording: Recording
    @StateObject private var player = AudioPlayerService.shared
    @Environment(\.dismiss) var dismiss
    @State private var isRenaming = false
    @State private var newName = ""
    @State private var showError = false
    @State private var errorMessage = ""

    private let fileManager = RecordingFileManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Recording info
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if isRenaming {
                                HStack {
                                    TextField("Recording name", text: $newName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onSubmit {
                                            saveNewName()
                                        }

                                    Button("Cancel") {
                                        isRenaming = false
                                        newName = recording.filename
                                    }

                                    Button("Save") {
                                        saveNewName()
                                    }
                                    .fontWeight(.semibold)
                                }
                            } else {
                                Text(recording.filename)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }

                            Text(formatDate(recording.recordedAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if !isRenaming {
                            Button {
                                newName = recording.filename
                                isRenaming = true
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .font(.title2)
                            }
                        }
                    }
                    .padding()

                    // File info
                    HStack(spacing: 20) {
                        VStack {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDuration(recording.duration))
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        Divider()
                            .frame(height: 30)

                        VStack {
                            Text("Size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatFileSize(recording.fileSize))
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        Divider()
                            .frame(height: 30)

                        VStack {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TranscriptionStatusView(status: recording.transcriptionStatus)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer()

                // Audio player controls
                VStack(spacing: 20) {
                    // Progress bar
                    VStack(spacing: 8) {
                        ProgressView(value: player.currentTime, total: player.duration)
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(y: 2)

                        HStack {
                            Text(formatTime(player.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(formatTime(player.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Playback controls
                    HStack(spacing: 40) {
                        Button {
                            player.skipBackward()
                        } label: {
                            Image(systemName: "gobackward.10")
                                .font(.title2)
                        }

                        Button {
                            if player.currentRecording?.id == recording.id {
                                if player.isPlaying {
                                    player.pause()
                                } else {
                                    player.resume()
                                }
                            } else {
                                player.play(recording: recording)
                            }
                        } label: {
                            Image(systemName: player.isPlaying && player.currentRecording?.id == recording.id ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }

                        Button {
                            player.skipForward()
                        } label: {
                            Image(systemName: "goforward.10")
                                .font(.title2)
                        }
                    }
                    .padding()

                    // Share button
                    Button {
                        shareRecording()
                    } label: {
                        Label("Share Recording", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)

                Spacer()
            }
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        player.stop()
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            if player.currentRecording?.id == recording.id {
                player.stop()
            }
        }
    }

    private func saveNewName() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Name cannot be empty"
            showError = true
            return
        }

        do {
            recording = try fileManager.renameRecording(recording, newName: trimmedName)
            isRenaming = false
        } catch {
            errorMessage = "Failed to rename: \(error.localizedDescription)"
            showError = true
        }
    }

    private func shareRecording() {
        var itemsToShare: [Any] = []

        let audioURL = URL(fileURLWithPath: recording.audioPath)
        if FileManager.default.fileExists(atPath: audioURL.path) {
            itemsToShare.append(audioURL)
        }

        if let transcriptPath = recording.transcriptPath {
            let transcriptURL = URL(fileURLWithPath: transcriptPath)
            if FileManager.default.fileExists(atPath: transcriptURL.path) {
                itemsToShare.append(transcriptURL)
            }
        }

        guard !itemsToShare.isEmpty else { return }

        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {

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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    RecordingDetailView(recording: Recording(
        filename: "meeting_2024-01-15_14-30-00",
        recordedAt: Date(),
        duration: 3600,
        fileSize: 15728640,
        transcriptionStatus: .completed,
        audioPath: "/path/to/audio.m4a"
    ))
}