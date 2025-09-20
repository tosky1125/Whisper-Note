import SwiftUI

struct TranscriptView: View {
    @Binding var recording: Recording
    @State private var transcriptText: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isEditing = false
    @State private var editedText: String = ""
    @Environment(\.dismiss) var dismiss

    private let fileManager = RecordingFileManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading transcript...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)

                        Text("Failed to load transcript")
                            .font(.headline)

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Retry") {
                            loadTranscript()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        if isEditing {
                            TextEditor(text: $editedText)
                                .padding()
                                .frame(minHeight: 400)
                        } else {
                            Text(transcriptText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle("Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isLoading && errorMessage == nil {
                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing {
                                saveTranscript()
                            } else {
                                editedText = transcriptText
                                isEditing = true
                            }
                        }
                    }
                }

                if isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            isEditing = false
                            editedText = transcriptText
                        }
                    }
                }
            }
        }
        .onAppear {
            loadTranscript()
        }
    }

    private func loadTranscript() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let text = try fileManager.loadTranscript(for: recording.filename)
                await MainActor.run {
                    transcriptText = text
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func saveTranscript() {
        do {
            try fileManager.saveTranscript(editedText, for: recording.filename)
            transcriptText = editedText
            isEditing = false

            // Update the recording's transcription status if needed
            if recording.transcriptionStatus != .completed {
                recording.transcriptionStatus = .completed
                recording.transcribedAt = Date()
                recording.transcriptPath = fileManager.transcriptURL(for: recording.filename).path

                let metadata = RecordingMetadata(from: recording)
                try? fileManager.saveMetadata(metadata)
            }
        } catch {
            errorMessage = "Failed to save transcript: \(error.localizedDescription)"
        }
    }
}

struct TranscriptShareView: View {
    let recording: Recording
    let transcript: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recording.filename)
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack {
                            Label(formatDate(recording.recordedAt), systemImage: "calendar")
                            Spacer()
                            Label(formatDuration(recording.duration), systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                    Divider()

                    // Transcript
                    Text(transcript)
                        .padding(.horizontal)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: createShareText()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private func createShareText() -> String {
        """
        Transcript: \(recording.filename)
        Date: \(formatDate(recording.recordedAt))
        Duration: \(formatDuration(recording.duration))

        ---

        \(transcript)
        """
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
}

#Preview {
    TranscriptView(recording: .constant(Recording(
        filename: "meeting_2024-01-15_14-30-00",
        recordedAt: Date(),
        duration: 3600,
        fileSize: 15728640,
        transcriptionStatus: .completed,
        audioPath: "/path/to/audio.m4a",
        transcriptPath: "/path/to/transcript.txt"
    )))
}