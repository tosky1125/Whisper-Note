import Foundation

enum RecordingState: String {
    case idle = "idle"
    case recording = "recording"
    case paused = "paused"
    case saving = "saving"
    case stopped = "stopped"

    var displayText: String {
        switch self {
        case .idle:
            return "Ready to Record"
        case .recording:
            return "Recording..."
        case .paused:
            return "Recording Paused"
        case .saving:
            return "Saving Recording..."
        case .stopped:
            return "Recording Stopped"
        }
    }

    var canStartRecording: Bool {
        return self == .idle || self == .stopped
    }

    var canPause: Bool {
        return self == .recording
    }

    var canResume: Bool {
        return self == .paused
    }

    var canStop: Bool {
        return self == .recording || self == .paused
    }

    var isActive: Bool {
        return self == .recording || self == .paused
    }
}