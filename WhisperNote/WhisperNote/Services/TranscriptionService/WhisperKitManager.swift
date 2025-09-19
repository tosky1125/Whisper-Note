import Foundation
import SwiftUI
import WhisperKit

@MainActor
class WhisperKitManager: ObservableObject {
    static let shared = WhisperKitManager()

    @Published var isModelDownloaded = false
    @Published var isDownloading = false
    @Published var downloadProgress: Float = 0
    @Published var downloadStatus = "Not Started"
    @Published var modelSize: String = "~250MB"
    @Published var whisperKit: WhisperKit?
    @Published var availableModels: [String] = []
    @Published var currentModel: String = "openai_whisper-small"

    private init() {
        checkModelStatus()
    }

    func checkModelStatus() {
        Task {
            do {
                // Check if model already exists
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let modelPath = documentsPath.appendingPathComponent("huggingface/models/argmaxinc/whisperkit-coreml")

                if FileManager.default.fileExists(atPath: modelPath.path) {
                    isModelDownloaded = true
                    downloadStatus = "Model Ready"

                    // Try to load the model
                    await loadWhisperKit()
                } else {
                    isModelDownloaded = false
                    downloadStatus = "Model Not Downloaded"
                }
            } catch {
                print("Error checking model status: \(error)")
                downloadStatus = "Error: \(error.localizedDescription)"
            }
        }
    }

    func downloadModel() async {
        guard !isDownloading else { return }

        isDownloading = true
        downloadStatus = "Preparing Download..."
        downloadProgress = 0

        do {
            // Initialize WhisperKit with the small German model
            downloadStatus = "Downloading Model..."

            whisperKit = try await WhisperKit(
                verbose: true,
                logLevel: .debug,
                prewarm: false,
                load: false,
                download: true
            )

            // Simulate progress updates (WhisperKit doesn't provide real-time progress)
            for i in 1...10 {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                downloadProgress = Float(i) / 10.0
                downloadStatus = "Downloading... \(Int(downloadProgress * 100))%"
            }

            isModelDownloaded = true
            downloadStatus = "Model Downloaded Successfully"
            downloadProgress = 1.0

            // Load the model after download
            await loadWhisperKit()

        } catch {
            downloadStatus = "Download Failed: \(error.localizedDescription)"
            isModelDownloaded = false
            print("Failed to download model: \(error)")
        }

        isDownloading = false
    }

    func loadWhisperKit() async {
        do {
            if whisperKit == nil {
                downloadStatus = "Loading Model..."

                whisperKit = try await WhisperKit(
                    verbose: true,
                    logLevel: .debug,
                    prewarm: true,
                    load: true,
                    download: false
                )

                downloadStatus = "Model Ready"
            }

            // Get available models
            if let whisper = whisperKit {
                availableModels = whisper.modelCompute.availableModels
            }

        } catch {
            downloadStatus = "Failed to Load Model"
            print("Failed to load WhisperKit: \(error)")
        }
    }

    func deleteModel() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let modelPath = documentsPath.appendingPathComponent("huggingface/models/argmaxinc/whisperkit-coreml")

            if FileManager.default.fileExists(atPath: modelPath.path) {
                try FileManager.default.removeItem(at: modelPath)
                isModelDownloaded = false
                downloadStatus = "Model Deleted"
                whisperKit = nil
                downloadProgress = 0
            }
        } catch {
            print("Failed to delete model: \(error)")
            downloadStatus = "Failed to Delete Model"
        }
    }

    func transcribeAudio(at url: URL, language: String = "de") async throws -> String {
        guard let whisperKit = whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        // Configure transcription options for German
        let options = DecodingOptions(
            language: language,
            temperature: 0,
            temperatureIncrementOnFallback: 0.2,
            temperatureFallbackCount: 3,
            sampleLength: 224,
            topK: 5,
            usePrefillPrompt: true,
            usePrefillCache: true,
            skipSpecialTokens: true,
            withoutTimestamps: false,
            clipTimestamps: true
        )

        // Perform transcription
        let results = try await whisperKit.transcribe(
            audioPath: url.path,
            decodeOptions: options
        )

        // Combine all segments into a single transcript
        let transcript = results?.compactMap { $0.text }.joined(separator: " ") ?? ""

        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case transcriptionFailed
    case audioFileNotFound

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "WhisperKit model is not loaded. Please download the model first."
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .audioFileNotFound:
            return "Audio file not found"
        }
    }
}