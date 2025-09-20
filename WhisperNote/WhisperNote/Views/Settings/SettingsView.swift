import SwiftUI

struct SettingsView: View {
    @AppStorage("autoTranscription") private var autoTranscription = true
    @AppStorage("audioQuality") private var audioQuality = "medium"
    @State private var showingAbout = false
    @State private var storageUsed: String = "Calculating..."
    @State private var showingCleanup = false

    private let fileManager = RecordingFileManager.shared

    var body: some View {
        NavigationView {
            Form {
                Section("Recording") {
                    Toggle("Auto-transcription", isOn: $autoTranscription)

                    Picker("Audio Quality", selection: $audioQuality) {
                        Text("Low (32 kbps)").tag("low")
                        Text("Medium (64 kbps)").tag("medium")
                        Text("High (128 kbps)").tag("high")
                    }
                }

                Section("WhisperKit Model") {
                    HStack {
                        Text("Model Version")
                        Spacer()
                        Text(WhisperKitManager.shared.currentModel)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        Text(WhisperKitManager.shared.downloadStatus)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        Task {
                            await WhisperKitManager.shared.checkModelStatus()
                        }
                    } label: {
                        Label("Check for Updates", systemImage: "arrow.clockwise")
                    }

                    Button {
                        Task {
                            WhisperKitManager.shared.deleteModel()
                            await WhisperKitManager.shared.downloadModel()
                        }
                    } label: {
                        Label("Re-download Model", systemImage: "arrow.down.circle")
                    }
                    .disabled(WhisperKitManager.shared.isDownloading)
                }

                Section("Storage") {
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text(storageUsed)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        showingCleanup = true
                    } label: {
                        Label("Clean Old Files", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }

                Section("Backup") {
                    Toggle("iCloud Backup", isOn: .constant(false))
                        .disabled(true)
                        .overlay(
                            Text("Coming Soon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .offset(x: -60, y: 0)
                        )
                }

                Section("About") {
                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Text("About WhisperNote")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                calculateStorageUsed()
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingCleanup) {
            StorageCleanupView(storageUsed: $storageUsed)
        }
    }

    private func calculateStorageUsed() {
        DispatchQueue.global(qos: .background).async {
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
                let formattedSize = formatter.string(fromByteCount: totalSize)

                DispatchQueue.main.async {
                    storageUsed = formattedSize
                }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("WhisperNote")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("On-device German audio transcription")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()
                    .padding(.horizontal, 40)

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "lock.shield", text: "Privacy-focused: All processing on device")
                    FeatureRow(icon: "network.slash", text: "No internet required")
                    FeatureRow(icon: "cpu", text: "Powered by WhisperKit")
                    FeatureRow(icon: "globe", text: "German language support")
                }
                .padding()

                Spacer()

                Text("© 2024 WhisperNote")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)

            Text(text)
                .font(.body)

            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}