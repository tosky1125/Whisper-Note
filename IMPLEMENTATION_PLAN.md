# 🎯 Whisper Note iOS App Implementation Plan

## Phase 0: Project Setup (1 day)

### 1. ✅ Create Xcode Project
- iOS 16.0+ target, SwiftUI
- Configure Bundle ID
- Setup Swift Package Manager

### 2. ✅ Add WhisperKit & Review Documentation
- Check WhisperKit audio format requirements
- Prepare automatic format conversion logic

### 3. ✅ Project Structure
```
WhisperNote/
├── App/
├── Models/
├── Services/
│   ├── AudioRecorder/
│   ├── TranscriptionService/
│   └── FileManager/
├── Views/
│   ├── Recording/
│   ├── Library/
│   └── Settings/
└── Resources/
```

---

## Phase 1: Data Layer (2 days)

### 4. ✅ Define Data Models
```swift
Recording {
  id: UUID
  filename: String
  recordedAt: Date
  duration: TimeInterval
  fileSize: Int64
  transcriptionStatus: Status
  audioPath: String
  transcriptPath: String?
}
```

### 5. ✅ FileManager Service
- Create Documents folder structure
- File CRUD operations
- Metadata JSON management

### 6. Data Migration System
- Handle schema changes per version
- Auto-run on app updates

---

## Phase 2: Core Audio Recording (3-4 days)

### 7. ✅ AudioRecorder Service
- Configure AVAudioSession
- **Audio Settings: 64kbps, 22kHz (medium quality)**
- Auto-convert to WhisperKit compatible format

### 8. ✅ Background Recording Handler
- Detect background entry
- **Start 30-second timer**
- **Trigger auto-save at 25 seconds**
- Stop recording after save
- Local notification: "Recording saved"

### 9. Recording State Management
- States: idle → recording → paused → saving → stopped
- Pause/resume functionality
- Auto-save logic

### 10. ✅ RecordingView UI
- Large record button
- Pause button
- Recording duration display
- Audio level meter
- Background status indicator

---

## Phase 3: WhisperKit Integration (4-5 days)

### 11. First Launch Model Download
- Detect first app launch
- Show model download screen
- Progress indicator (MB/total MB)
- Navigate to main after completion

### 12. TranscriptionService Implementation
- Initialize WhisperKit
- Auto-convert audio format if needed
- Process in 5-minute chunks
- German language setting

### 13. Offline Handling
- Check model existence
- **No model: Save recording only, show "Transcribe later"**
- Model exists: Start auto-transcription

### 14. Model Updates
- "Check for updates" button in Settings
- Download option when new version available
- Background download support

---

## Phase 4: Library Screen (3 days)

### 15. LibraryViewModel
- Load recording list
- Filter by status
- Sort: date/size/duration

### 16. LibraryView UI
- List display
- Item info:
  * Filename/date
  * Recording duration
  * Transcription status
  * File size

### 17. Swipe Actions
- Left: Share options
- Right: Delete (confirm required)
- Tap: Details/playback

### 18. Batch Processing
- Batch transcribe unprocessed files
- Show progress

---

## Phase 5: Sharing Feature (2 days)

### 19. File Export
- Audio: m4a original
- Text: txt file
- Options: audio only/text only/both

### 20. iOS Share Sheet Integration
- AirDrop
- Messages/Email
- Save to Files app
- Third-party apps

---

## Phase 6: Settings Screen (2 days)

### 21. Basic Settings
- Auto-transcription ON/OFF
- Recording quality (for future)
- Language setting (current: German)

### 22. WhisperKit Model Management
- Display current model version
- Show model size
- "Check for updates" button
- Re-download model option

### 23. Storage Management
- Show total usage
- Audio/text breakdown
- Clean old files

### 24. Backup Settings
- iCloud backup toggle
- Files app access

---

## Phase 7: Stability & Optimization (2-3 days)

### 25. Enhanced Error Handling
- Retry on save failure
- Transcription failure recovery
- Background save failure handling

### 26. Performance Optimization
- Memory usage profiling
- Large file handling
- UI responsiveness

### 27. Background Stability
- Accurate 30-second limit handling
- Save time optimization
- Recovery mechanisms

---

## Phase 8: Testing & Release (3 days)

### 28. Core Scenario Testing
- Normal recording → save → transcription
- Background recording → auto-save before 30s
- Offline recording → download model → process
- Long recording (1hr+)

### 29. Edge Case Testing
- Low storage
- Phone call during background
- App force quit recovery
- Network loss during model download

### 30. App Store Preparation
- App icon/splash screen
- Screenshots (iPhone 15 Pro)
- App description (German/English)
- Privacy policy

---

## 📱 Implementation Priority (Weekly)

### Week 1: Core Foundation
- ✅ Project setup
- ✅ Audio recording (medium quality)
- ✅ Background 30s auto-save

### Week 2: WhisperKit
- ✅ First launch model download
- ✅ Audio format auto-conversion
- ✅ Basic transcription

### Week 3: User Interface
- ✅ Library screen
- ✅ File management
- ✅ Share functionality

### Week 4: Polish
- ✅ Settings screen
- ✅ Model update check
- ✅ Offline mode handling

### Week 5: Release
- ✅ Full testing
- ✅ Bug fixes
- ✅ App Store submission

---

## 🔑 Key Implementation Points

### 1. Background Recording Safety
```swift
// On background entry
backgroundTaskID = UIApplication.shared.beginBackgroundTask()

// Set 25-second timer
Timer.scheduledTimer(withTimeInterval: 25.0) { _ in
    saveRecording()
    stopRecording()
    sendLocalNotification("Recording saved")
}
```

### 2. WhisperKit Format Conversion
```swift
// After checking WhisperKit requirements
if !isCompatibleFormat(audioFile) {
    convertToWhisperKitFormat(audioFile)
}
```

### 3. Offline Mode
```swift
if !modelExists() {
    // Save recording only
    saveAudioOnly()
    showMessage("Transcription available after model download")
} else {
    startTranscription()
}
```

**Total estimated development time: 4-5 weeks**

---

## Progress Tracker

### Completed Tasks ✅
- [x] Task 1: Create Xcode project with iOS 16.0+ target and SwiftUI
- [x] Task 2: Add WhisperKit package dependency
- [x] Task 3: Setup project folder structure
- [x] Task 4: Create data models (Recording, Metadata)
- [x] Task 5: Implement FileManager service for document storage
- [x] Task 7: Create AudioRecorder service with background save
- [x] Task 8: Implement RecordingView UI with pause functionality

### In Progress 🔄
- [ ] Task 9: Setup main TabView navigation

### Pending ⏳
- [ ] Task 10: Test basic recording and saving functionality
- [ ] Task 11: First Launch Model Download
- [ ] Task 12: TranscriptionService Implementation
- [ ] Task 13: Offline Handling
- [ ] Task 14: Model Updates
- [ ] Task 15-30: Remaining implementation tasks