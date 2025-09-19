import SwiftUI

struct RecordingView: View {
    @StateObject private var recorder = AudioRecorderService.shared
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()

                // Audio level meter
                AudioLevelMeter(level: recorder.audioLevel)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                    .opacity(recorder.recordingState.isActive ? 1 : 0.3)

                // Duration display
                Text(formatDuration(recorder.recordingDuration))
                    .font(.system(size: 48, weight: .medium, design: .monospaced))
                    .foregroundColor(recorder.recordingState.isActive ? .primary : .secondary)

                Spacer()

                // Recording controls
                HStack(spacing: 60) {
                    // Pause/Resume button
                    if recorder.recordingState.isActive {
                        Button(action: {
                            if recorder.recordingState == .paused {
                                recorder.resumeRecording()
                            } else {
                                recorder.pauseRecording()
                            }
                        }) {
                            Image(systemName: recorder.recordingState == .paused ? "play.fill" : "pause.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .transition(.scale)
                    }

                    // Main record button
                    Button(action: {
                        handleRecordButtonTapped()
                    }) {
                        ZStack {
                            Circle()
                                .fill(recorder.recordingState.isActive ? Color.red : Color.red.opacity(0.8))
                                .frame(width: 100, height: 100)

                            if recorder.recordingState.isActive {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(width: 35, height: 35)
                            } else {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 35, height: 35)
                            }
                        }
                        .shadow(radius: recorder.recordingState.isActive ? 10 : 5)
                        .scaleEffect(recorder.recordingState.isActive ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: recorder.recordingState)
                    }

                    // Placeholder for symmetry
                    if recorder.recordingState.isActive {
                        Color.clear
                            .frame(width: 60, height: 60)
                    }
                }

                // Status text
                Text(getStatusText())
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)

                Spacer()
            }
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Microphone Permission", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("WhisperNote needs access to your microphone to record audio. Please enable microphone access in Settings.")
        }
        .alert("Permission Denied", isPresented: $permissionDenied) {
            Button("OK") { }
        } message: {
            Text("Microphone access was denied. Please enable it in Settings to use recording features.")
        }
    }

    private func handleRecordButtonTapped() {
        if recorder.recordingState.isActive {
            recorder.stopRecording()
        } else {
            recorder.requestMicrophonePermission { granted in
                if granted {
                    recorder.startRecording()
                } else {
                    permissionDenied = true
                }
            }
        }
    }

    private func getStatusText() -> String {
        switch recorder.recordingState {
        case .idle, .stopped:
            return "Tap to Start Recording"
        case .recording:
            return "Recording..."
        case .paused:
            return "Recording Paused"
        case .saving:
            return "Saving..."
        }
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

struct AudioLevelMeter: View {
    let level: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))

                // Level indicator
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(level))
                    .animation(.linear(duration: 0.1), value: level)
            }
        }
    }
}

#Preview {
    RecordingView()
}