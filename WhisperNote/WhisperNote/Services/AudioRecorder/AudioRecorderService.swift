import Foundation
import AVFoundation
import UIKit

class AudioRecorderService: NSObject, ObservableObject {
    static let shared = AudioRecorderService()

    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTimer: Timer?
    private let fileManager = RecordingFileManager.shared

    private var currentFilename: String?
    private var recordingStartTime: Date?

    override private init() {
        super.init()
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func handleAppDidEnterBackground() {
        if isRecording {
            startBackgroundTask()
            startBackgroundSaveTimer()
        }
    }

    @objc private func handleAppWillEnterForeground() {
        cancelBackgroundSaveTimer()
        endBackgroundTask()
    }

    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.saveAndStopRecording()
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    private func startBackgroundSaveTimer() {
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: false) { [weak self] _ in
            self?.saveAndStopRecording()
            self?.sendLocalNotification()
        }
    }

    private func cancelBackgroundSaveTimer() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil
    }

    private func sendLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Recording Saved"
        content.body = "Your recording has been saved successfully."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)

            currentFilename = fileManager.generateFilename()
            guard let filename = currentFilename else { return }

            let audioURL = fileManager.audioURL(for: filename)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 22050,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 64000,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true

            if audioRecorder?.record() == true {
                isRecording = true
                isPaused = false
                recordingStartTime = Date()
                startTimer()
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func pauseRecording() {
        guard isRecording, !isPaused else { return }

        audioRecorder?.pause()
        isPaused = true
        timer?.invalidate()
    }

    func resumeRecording() {
        guard isRecording, isPaused else { return }

        audioRecorder?.record()
        isPaused = false
        startTimer()
    }

    func stopRecording() {
        saveAndStopRecording()
    }

    private func saveAndStopRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        isRecording = false
        isPaused = false
        timer?.invalidate()
        cancelBackgroundSaveTimer()
        endBackgroundTask()

        saveRecordingMetadata()

        recordingDuration = 0
        audioLevel = 0
    }

    private func saveRecordingMetadata() {
        guard let filename = currentFilename else { return }

        let audioURL = fileManager.audioURL(for: filename)
        let fileSize = fileManager.getFileSize(at: audioURL.path)
        let duration = fileManager.getAudioDuration(at: audioURL)

        let recording = Recording(
            filename: filename,
            recordedAt: recordingStartTime ?? Date(),
            duration: duration,
            fileSize: fileSize,
            transcriptionStatus: .pending,
            audioPath: audioURL.path
        )

        let metadata = RecordingMetadata(from: recording)

        do {
            try fileManager.saveMetadata(metadata)
        } catch {
            print("Failed to save metadata: \(error)")
        }

        currentFilename = nil
        recordingStartTime = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateMeters()
        }
    }

    private func updateMeters() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()

        if let startTime = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(startTime)
        }

        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedPower = pow(10, averagePower / 20)
        audioLevel = max(0, min(1, normalizedPower))
    }
}

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully")
        } else {
            print("Recording failed")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
        }
    }
}