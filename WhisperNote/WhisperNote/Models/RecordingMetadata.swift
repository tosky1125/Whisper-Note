import Foundation

struct RecordingMetadata: Codable {
    let id: UUID
    let filename: String
    let recordedAt: Date
    let duration: TimeInterval
    let fileSize: Int64
    let language: String
    var transcriptionStatus: String
    var transcribedAt: Date?

    init(from recording: Recording) {
        self.id = recording.id
        self.filename = recording.filename
        self.recordedAt = recording.recordedAt
        self.duration = recording.duration
        self.fileSize = recording.fileSize
        self.language = recording.language
        self.transcriptionStatus = recording.transcriptionStatus.rawValue
        self.transcribedAt = recording.transcribedAt
    }

    func toRecording(audioPath: String, transcriptPath: String?) -> Recording {
        return Recording(
            id: id,
            filename: filename,
            recordedAt: recordedAt,
            duration: duration,
            fileSize: fileSize,
            transcriptionStatus: TranscriptionStatus(rawValue: transcriptionStatus) ?? .pending,
            audioPath: audioPath,
            transcriptPath: transcriptPath,
            language: language,
            transcribedAt: transcribedAt
        )
    }
}