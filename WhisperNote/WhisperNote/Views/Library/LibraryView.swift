import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedRecording: Recording?
    @State private var showingDeleteAlert = false
    @State private var recordingToDelete: Recording?

    var body: some View {
        NavigationView {
            List {
                if viewModel.recordings.isEmpty {
                    EmptyLibraryView()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                } else {
                    ForEach(viewModel.recordings) { recording in
                        RecordingRowView(recording: recording)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRecording = recording
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    recordingToDelete = recording
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    viewModel.shareRecording(recording, audioOnly: true)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                if recording.transcriptionStatus == .pending {
                                    Button {
                                        viewModel.transcribeRecording(recording)
                                    } label: {
                                        Label("Transcribe", systemImage: "text.viewfinder")
                                    }
                                    .tint(.orange)
                                }
                            }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshRecordings()
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.sortBy(.date)
                        } label: {
                            Label("Sort by Date", systemImage: "calendar")
                        }

                        Button {
                            viewModel.sortBy(.duration)
                        } label: {
                            Label("Sort by Duration", systemImage: "clock")
                        }

                        Button {
                            viewModel.sortBy(.size)
                        } label: {
                            Label("Sort by Size", systemImage: "doc")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .alert("Delete Recording", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let recording = recordingToDelete {
                    viewModel.deleteRecording(recording)
                }
            }
        } message: {
            Text("Are you sure you want to delete this recording? This action cannot be undone.")
        }
        .sheet(item: $selectedRecording) { recording in
            RecordingDetailView(recording: recording)
        }
    }
}

struct RecordingRowView: View {
    let recording: Recording

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.filename)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text(formatDate(recording.recordedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(formatDuration(recording.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(formatFileSize(recording.fileSize))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            TranscriptionStatusView(status: recording.transcriptionStatus)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm %ds", minutes, seconds)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct TranscriptionStatusView: View {
    let status: TranscriptionStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.caption)

            Text(status.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch status {
        case .pending:
            return Color.gray.opacity(0.2)
        case .processing:
            return Color.blue.opacity(0.2)
        case .completed:
            return Color.green.opacity(0.2)
        case .failed:
            return Color.red.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .pending:
            return Color.gray
        case .processing:
            return Color.blue
        case .completed:
            return Color.green
        case .failed:
            return Color.red
        }
    }
}

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Recordings Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start recording to see your audio files here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    LibraryView()
}