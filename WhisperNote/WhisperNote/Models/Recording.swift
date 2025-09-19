import Foundation

struct Recording: Identifiable, Codable {
    let id: UUID
    var filename: String
    let recordedAt: Date
    let duration: TimeInterval
    let fileSize: Int64
    var transcriptionStatus: TranscriptionStatus
    var audioPath: String
    var transcriptPath: String?
    let language: String
    var transcribedAt: Date?

    init(
        id: UUID = UUID(),
        filename: String,
        recordedAt: Date = Date(),
        duration: TimeInterval,
        fileSize: Int64,
        transcriptionStatus: TranscriptionStatus = .pending,
        audioPath: String,
        transcriptPath: String? = nil,
        language: String = "de",
        transcribedAt: Date? = nil
    ) {
        self.id = id
        self.filename = filename
        self.recordedAt = recordedAt
        self.duration = duration
        self.fileSize = fileSize
        self.transcriptionStatus = transcriptionStatus
        self.audioPath = audioPath
        self.transcriptPath = transcriptPath
        self.language = language
        self.transcribedAt = transcribedAt
    }
}

enum TranscriptionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }

    var iconName: String {
        switch self {
        case .pending:
            return "clock"
        case .processing:
            return "arrow.trianglehead.2.clockwise"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
}