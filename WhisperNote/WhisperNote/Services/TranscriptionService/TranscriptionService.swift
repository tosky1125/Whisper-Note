import Foundation
import SwiftUI
import AVFoundation

@MainActor
class TranscriptionService: ObservableObject {
    static let shared = TranscriptionService()

    @Published var isTranscribing = false
    @Published var transcriptionQueue: [Recording] = []
    @Published var currentProgress: Float = 0
    @Published var currentRecordingName = ""

    private let fileManager = RecordingFileManager.shared
    private let whisperManager = WhisperKitManager.shared
    @AppStorage("autoTranscription") private var autoTranscription = true

    private init() { }

    func addToQueue(_ recording: Recording) {
        guard recording.transcriptionStatus != .completed else { return }

        if !transcriptionQueue.contains(where: { $0.id == recording.id }) {
            transcriptionQueue.append(recording)
        }

        if !isTranscribing {
            Task {
                await processQueue()
            }
        }
    }

    func transcribeRecording(_ recording: Recording) async throws -> String {
        // Check if model is available
        guard whisperManager.isModelDownloaded else {
            throw TranscriptionError.modelNotLoaded
        }

        // Update status to processing
        var updatedRecording = recording
        updatedRecording.transcriptionStatus = .processing
        let metadata = RecordingMetadata(from: updatedRecording)
        try fileManager.saveMetadata(metadata)

        currentRecordingName = recording.filename
        currentProgress = 0

        do {
            // Get audio file URL
            let audioURL = URL(fileURLWithPath: recording.audioPath)

            // Check if file exists
            guard FileManager.default.fileExists(atPath: audioURL.path) else {
                throw TranscriptionError.audioFileNotFound
            }

            // Process in chunks for long audio
            let duration = recording.duration
            let chunkDuration: TimeInterval = 300 // 5 minutes
            let numberOfChunks = Int(ceil(duration / chunkDuration))

            var fullTranscript = ""

            if numberOfChunks > 1 {
                // Process in chunks
                for i in 0..<numberOfChunks {
                    currentProgress = Float(i) / Float(numberOfChunks)

                    // Create chunk file
                    let startTime = TimeInterval(i) * chunkDuration
                    let endTime = min(startTime + chunkDuration, duration)

                    if let chunkURL = try await extractAudioChunk(
                        from: audioURL,
                        startTime: startTime,
                        endTime: endTime,
                        chunkIndex: i
                    ) {
                        let chunkTranscript = try await whisperManager.transcribeAudio(at: chunkURL, language: "de")
                        fullTranscript += chunkTranscript + " "

                        // Clean up chunk file
                        try? FileManager.default.removeItem(at: chunkURL)
                    }
                }
            } else {
                // Process entire file
                fullTranscript = try await whisperManager.transcribeAudio(at: audioURL, language: "de")
            }

            // Save transcript
            let finalTranscript = fullTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            try fileManager.saveTranscript(finalTranscript, for: recording.filename)

            // Update recording metadata
            updatedRecording.transcriptionStatus = .completed
            updatedRecording.transcribedAt = Date()
            updatedRecording.transcriptPath = fileManager.transcriptURL(for: recording.filename).path

            let finalMetadata = RecordingMetadata(from: updatedRecording)
            try fileManager.saveMetadata(finalMetadata)

            currentProgress = 1.0
            return finalTranscript

        } catch {
            // Update status to failed
            updatedRecording.transcriptionStatus = .failed
            let failedMetadata = RecordingMetadata(from: updatedRecording)
            try? fileManager.saveMetadata(failedMetadata)

            throw error
        }
    }

    private func extractAudioChunk(
        from url: URL,
        startTime: TimeInterval,
        endTime: TimeInterval,
        chunkIndex: Int
    ) async throws -> URL? {
        let asset = AVAsset(url: url)

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            return nil
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("chunk_\(chunkIndex).m4a")

        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = CMTimeRange(
            start: CMTime(seconds: startTime, preferredTimescale: 1),
            end: CMTime(seconds: endTime, preferredTimescale: 1)
        )

        await exportSession.export()

        if exportSession.status == .completed {
            return outputURL
        } else {
            return nil
        }
    }

    private func processQueue() async {
        guard !isTranscribing else { return }

        isTranscribing = true

        while !transcriptionQueue.isEmpty {
            let recording = transcriptionQueue.removeFirst()

            do {
                _ = try await transcribeRecording(recording)
            } catch {
                print("Transcription failed for \(recording.filename): \(error)")
            }
        }

        isTranscribing = false
        currentProgress = 0
        currentRecordingName = ""
    }

    func processNewRecording(_ recording: Recording) {
        guard autoTranscription else { return }
        guard whisperManager.isModelDownloaded else { return }

        addToQueue(recording)
    }

    func batchTranscribe(recordings: [Recording]) {
        let pendingRecordings = recordings.filter { $0.transcriptionStatus == .pending }

        for recording in pendingRecordings {
            addToQueue(recording)
        }
    }
}