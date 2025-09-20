import Foundation
import AVFoundation

class RecordingFileManager {
    static let shared = RecordingFileManager()

    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    private let audioFolder = "Audio"
    private let transcriptsFolder = "Transcripts"
    private let metadataFolder = "Metadata"

    private init() {
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        createDirectoryStructure()
    }

    private func createDirectoryStructure() {
        let folders = [audioFolder, transcriptsFolder, metadataFolder]

        for folder in folders {
            let folderURL = documentsDirectory.appendingPathComponent(folder)

            if !fileManager.fileExists(atPath: folderURL.path) {
                try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }

    func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "meeting_\(formatter.string(from: Date()))"
    }

    func audioURL(for filename: String) -> URL {
        return documentsDirectory
            .appendingPathComponent(audioFolder)
            .appendingPathComponent("\(filename).m4a")
    }

    func transcriptURL(for filename: String) -> URL {
        return documentsDirectory
            .appendingPathComponent(transcriptsFolder)
            .appendingPathComponent("\(filename).txt")
    }

    func metadataURL(for filename: String) -> URL {
        return documentsDirectory
            .appendingPathComponent(metadataFolder)
            .appendingPathComponent("\(filename).json")
    }

    func saveMetadata(_ metadata: RecordingMetadata) throws {
        let url = metadataURL(for: metadata.filename)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(metadata)
        try data.write(to: url)
    }

    func loadMetadata(for filename: String) throws -> RecordingMetadata {
        let url = metadataURL(for: filename)
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(RecordingMetadata.self, from: data)
    }

    func loadAllRecordings() -> [Recording] {
        let metadataFolderURL = documentsDirectory.appendingPathComponent(metadataFolder)

        guard let metadataFiles = try? fileManager.contentsOfDirectory(
            at: metadataFolderURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        var recordings: [Recording] = []

        for metadataFile in metadataFiles {
            if metadataFile.pathExtension == "json" {
                let filename = metadataFile.deletingPathExtension().lastPathComponent

                if let metadata = try? loadMetadata(for: filename) {
                    let audioPath = audioURL(for: filename).path
                    let transcriptPath = transcriptURL(for: filename).path

                    let recording = metadata.toRecording(
                        audioPath: audioPath,
                        transcriptPath: fileManager.fileExists(atPath: transcriptPath) ? transcriptPath : nil
                    )

                    recordings.append(recording)
                }
            }
        }

        return recordings.sorted { $0.recordedAt > $1.recordedAt }
    }

    func deleteRecording(_ recording: Recording) throws {
        let audioURL = URL(fileURLWithPath: recording.audioPath)
        if fileManager.fileExists(atPath: audioURL.path) {
            try fileManager.removeItem(at: audioURL)
        }

        if let transcriptPath = recording.transcriptPath {
            let transcriptURL = URL(fileURLWithPath: transcriptPath)
            if fileManager.fileExists(atPath: transcriptURL.path) {
                try fileManager.removeItem(at: transcriptURL)
            }
        }

        let metadataURL = metadataURL(for: recording.filename)
        if fileManager.fileExists(atPath: metadataURL.path) {
            try fileManager.removeItem(at: metadataURL)
        }
    }

    func renameRecording(_ recording: Recording, newName: String) throws -> Recording {
        let oldFilename = recording.filename
        let newFilename = newName

        // Rename audio file
        let oldAudioURL = audioURL(for: oldFilename)
        let newAudioURL = audioURL(for: newFilename)
        if fileManager.fileExists(atPath: oldAudioURL.path) {
            try fileManager.moveItem(at: oldAudioURL, to: newAudioURL)
        }

        // Rename transcript file if exists
        var newTranscriptPath: String? = nil
        if recording.transcriptPath != nil {
            let oldTranscriptURL = transcriptURL(for: oldFilename)
            let newTranscriptURL = transcriptURL(for: newFilename)
            if fileManager.fileExists(atPath: oldTranscriptURL.path) {
                try fileManager.moveItem(at: oldTranscriptURL, to: newTranscriptURL)
                newTranscriptPath = newTranscriptURL.path
            }
        }

        // Create updated recording
        var updatedRecording = recording
        updatedRecording.filename = newFilename
        updatedRecording.audioPath = newAudioURL.path
        updatedRecording.transcriptPath = newTranscriptPath

        // Update metadata
        let oldMetadataURL = metadataURL(for: oldFilename)
        if fileManager.fileExists(atPath: oldMetadataURL.path) {
            try fileManager.removeItem(at: oldMetadataURL)
        }

        let newMetadata = RecordingMetadata(from: updatedRecording)
        try saveMetadata(newMetadata)

        return updatedRecording
    }

    func saveTranscript(_ text: String, for filename: String) throws {
        let url = transcriptURL(for: filename)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    func loadTranscript(for filename: String) throws -> String {
        let url = transcriptURL(for: filename)
        return try String(contentsOf: url, encoding: .utf8)
    }

    func getFileSize(at path: String) -> Int64 {
        guard let attributes = try? fileManager.attributesOfItem(atPath: path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }
        return fileSize
    }

    func getAudioDuration(at url: URL) -> TimeInterval {
        let asset = AVAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }

    func getAudioDuration(at path: String) -> TimeInterval {
        let url = URL(fileURLWithPath: path)
        return getAudioDuration(at: url)
    }

    func listRecordings() -> [Recording] {
        return loadAllRecordings()
    }
}