import SwiftUI

struct StorageCleanupView: View {
    @Binding var storageUsed: String
    @Environment(\.dismiss) var dismiss
    @State private var recordings: [Recording] = []
    @State private var selectedDays = 30
    @State private var estimatedRecovery: String = "Calculating..."
    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @State private var recordingsToDelete: [Recording] = []

    private let fileManager = RecordingFileManager.shared
    private let dayOptions = [7, 14, 30, 60, 90]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "externaldrive.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading) {
                                    Text("Storage Used")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(storageUsed)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    Section("Cleanup Options") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Delete recordings older than:")
                                .font(.headline)

                            Picker("Days", selection: $selectedDays) {
                                ForEach(dayOptions, id: \.self) { days in
                                    Text("\(days) days").tag(days)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedDays) { _ in
                                calculateEstimatedRecovery()
                            }

                            HStack {
                                Label("Estimated recovery", systemImage: "arrow.down.circle")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(estimatedRecovery)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Recordings to Delete") {
                        if recordingsToDelete.isEmpty {
                            Text("No recordings match the criteria")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(recordingsToDelete) { recording in
                                RecordingCleanupRow(recording: recording)
                            }
                        }
                    }
                }

                // Bottom action button
                VStack {
                    Button {
                        if !recordingsToDelete.isEmpty {
                            showDeleteConfirmation = true
                        }
                    } label: {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Deleting...")
                            } else {
                                Image(systemName: "trash")
                                Text("Delete \(recordingsToDelete.count) Recording\(recordingsToDelete.count == 1 ? "" : "s")")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(recordingsToDelete.isEmpty ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(recordingsToDelete.isEmpty || isDeleting)
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Storage Cleanup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isDeleting)
                }
            }
            .onAppear {
                loadRecordings()
                calculateEstimatedRecovery()
            }
            .alert("Delete Recordings?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteOldRecordings()
                }
            } message: {
                Text("This will permanently delete \(recordingsToDelete.count) recording\(recordingsToDelete.count == 1 ? "" : "s") and free up \(estimatedRecovery). This action cannot be undone.")
            }
        }
    }

    private func loadRecordings() {
        recordings = fileManager.listRecordings()
    }

    private func calculateEstimatedRecovery() {
        let cutoffDate = Date().addingTimeInterval(-Double(selectedDays) * 24 * 60 * 60)
        recordingsToDelete = recordings.filter { $0.recordedAt < cutoffDate }

        let totalSize = recordingsToDelete.reduce(0) { sum, recording in
            sum + recording.fileSize
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        estimatedRecovery = formatter.string(fromByteCount: totalSize)
    }

    private func deleteOldRecordings() {
        isDeleting = true

        Task {
            var deletedSize: Int64 = 0

            for recording in recordingsToDelete {
                do {
                    try fileManager.deleteRecording(recording)
                    deletedSize += recording.fileSize
                } catch {
                    print("Failed to delete \(recording.filename): \(error)")
                }
            }

            // Recalculate storage after deletion
            await MainActor.run {
                recordings = fileManager.listRecordings()
                recordingsToDelete.removeAll()
                calculateEstimatedRecovery()
                updateStorageUsed()
                isDeleting = false

                // Show success and dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }
    }

    private func updateStorageUsed() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        if let enumerator = FileManager.default.enumerator(at: documentsURL,
                                                           includingPropertiesForKeys: [.fileSizeKey],
                                                           options: []) {
            var totalSize: Int64 = 0

            for case let fileURL as URL in enumerator {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }

            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            storageUsed = formatter.string(fromByteCount: totalSize)
        }
    }
}

struct RecordingCleanupRow: View {
    let recording: Recording

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recording.filename)
                .font(.subheadline)
                .lineLimit(1)

            HStack {
                Label(formatDate(recording.recordedAt), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formatFileSize(recording.fileSize))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    StorageCleanupView(storageUsed: .constant("125.4 MB"))
}