import SwiftUI

struct ModelDownloadView: View {
    @StateObject private var whisperManager = WhisperKitManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App Icon
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 20)

            // Title
            Text("Welcome to WhisperNote")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("To transcribe your recordings, we need to download the German language model")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Model Info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.zipper")
                    Text("Model Size: \(whisperManager.modelSize)")
                }

                HStack {
                    Image(systemName: "network.slash")
                    Text("Works offline after download")
                }

                HStack {
                    Image(systemName: "lock.shield")
                    Text("All processing on device")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            Spacer()

            // Download Section
            VStack(spacing: 20) {
                if whisperManager.isDownloading {
                    VStack(spacing: 12) {
                        ProgressView(value: whisperManager.downloadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(y: 2)

                        Text(whisperManager.downloadStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(whisperManager.downloadProgress * 100))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 40)
                } else if whisperManager.isModelDownloaded {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Model Downloaded")
                            .font(.headline)

                        Button {
                            hasCompletedOnboarding = true
                        } label: {
                            Text("Start Using WhisperNote")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    VStack(spacing: 12) {
                        Text(whisperManager.downloadStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            Task {
                                await whisperManager.downloadModel()
                            }
                        } label: {
                            Label("Download Model", systemImage: "arrow.down.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)

                        Button {
                            hasCompletedOnboarding = true
                        } label: {
                            Text("Skip (Recording Only)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .alert("Download Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            whisperManager.checkModelStatus()
        }
    }
}

#Preview {
    ModelDownloadView()
}