# Whisper Note - iOS Meeting Transcription App

## Overview
An iOS application for recording meetings and transcribing German audio to text using WhisperKit (on-device processing).

## Core Requirements

### Functional Requirements
- **Audio Recording**: Record meetings with high quality audio
- **File Persistence**: Save original audio files permanently
- **Transcription**: Convert German audio to text using WhisperKit small model
- **File Management**: Maintain both original audio and generated transcripts
- **Sharing**: Export files via AirDrop, email, and other iOS sharing options

### Non-Functional Requirements
- On-device processing (no internet required)
- Privacy-focused (no data leaves device)
- iOS 16.0+ compatibility
- iPhone 15 Pro optimized

---

## Technical Specifications

### Development Stack
- **Platform**: iOS 16.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **ML Model**: WhisperKit (small model)
- **Audio**: AVFoundation

### Dependencies
```
- WhisperKit (MIT License)
- No external API requirements
- No backend server needed
```

---

## Architecture

### Data Structure

```
Documents/
├── Audio/
│   └── meeting_YYYY-MM-DD_HH-mm-ss.m4a
├── Transcripts/
│   └── meeting_YYYY-MM-DD_HH-mm-ss.txt
└── Metadata/
    └── meeting_YYYY-MM-DD_HH-mm-ss.json
```

### Metadata Schema
```json
{
  "id": "UUID",
  "filename": "meeting_2024-01-15_14-30-00",
  "recordedAt": "2024-01-15T14:30:00Z",
  "duration": 3600,
  "fileSize": 15728640,
  "language": "de",
  "transcriptionStatus": "completed|pending|processing|failed",
  "transcribedAt": "2024-01-15T15:30:00Z"
}
```

---

## User Interface

### Screen Architecture

#### 1. Main Tab Bar
- **Record Tab**: Primary recording interface
- **Library Tab**: File management
- **Settings Tab**: App configuration

#### 2. Recording Screen
- Central record button (large, prominent)
- Recording timer display
- Audio level indicator
- Background recording capability

#### 3. Library Screen
- List view with recordings
- Sort options (date, duration, name)
- Swipe actions:
  - Share (audio/transcript/both)
  - Transcribe (if not processed)
  - Delete (with confirmation)
- Visual indicators:
  - Processing status
  - File type icons
  - Duration display

#### 4. Settings Screen
- Audio quality selection (High/Medium/Low)
- Auto-transcription toggle
- Storage management
- Model selection (future: small/medium/large)
- Language settings

---

## Core Workflows

### Recording Flow
```
1. User taps record button
2. Request microphone permission (first time only)
3. Start recording with visual feedback
4. Display duration counter
5. User taps stop button
6. Save audio file to Documents/Audio/
7. Create metadata entry
8. Add to library view
```

### Transcription Flow
```
1. User selects audio file
2. Tap "Transcribe" action
3. Load WhisperKit model (cached after first use)
4. Show progress indicator
5. Process audio in chunks
6. Save transcript to Documents/Transcripts/
7. Update metadata
8. Display completion notification
```

### Sharing Flow
```
1. User selects file(s)
2. Choose share action
3. Select sharing options:
   - Audio only
   - Transcript only
   - Both files
4. Present iOS share sheet
5. Handle sharing completion
```

---

## Performance Considerations

### Optimization Targets
- Model loading: < 5 seconds (first launch)
- Recording start: < 0.5 seconds
- Transcription speed: ~6x realtime (10min audio = 60min processing)
- Memory usage: < 2GB during transcription

### Resource Management
- Maximum recording duration: 3 hours
- Concurrent transcriptions: 1
- Background processing time: 30 seconds
- Model cache: ~250MB (small model)

### Battery Optimization
- Suspend transcription in low power mode
- Queue processing when charging
- Efficient audio compression

---

## Error Handling

### Error Scenarios

| Error Type | User Message | Recovery Action |
|------------|--------------|-----------------|
| Microphone Permission | "Microphone access required for recording" | Open Settings |
| Storage Full | "Insufficient storage space" | Manage files |
| Transcription Failed | "Unable to process audio" | Retry option |
| Model Download Failed | "Unable to download language model" | Retry/Offline mode |
| Memory Warning | "Processing paused due to memory" | Process smaller chunks |

---

## Development Phases

### Phase 1: MVP (Week 1-4)
- [ ] Project setup and configuration
- [ ] Basic recording functionality
- [ ] File storage system
- [ ] Simple library view
- [ ] WhisperKit integration
- [ ] Basic transcription
- [ ] Share functionality
- [ ] Essential settings

### Phase 2: Enhancement (Week 5-8)
- [ ] Background processing
- [ ] Progress indicators
- [ ] Audio visualization
- [ ] File search
- [ ] Batch operations
- [ ] Export formats (PDF, DOCX)

### Phase 3: Advanced Features (Future)
- [ ] Translation support (German → Korean/English)
- [ ] Real-time transcription
- [ ] Speaker diarization
- [ ] Cloud backup
- [ ] Multiple model support (medium/large)
- [ ] Server-side processing option

---

## Testing Strategy

### Test Scenarios
1. **Short Recording** (30 seconds)
2. **Long Recording** (1+ hour)
3. **Noisy Environment** 
4. **Multiple Speakers**
5. **App Interruption** (calls, notifications)
6. **Background Processing**
7. **Low Storage** (< 100MB)
8. **Low Battery** (< 20%)

### Device Testing
- iPhone 15 Pro (primary)
- iPhone 14
- iPhone 13 mini
- iPad (compatibility)

---

## Privacy & Security

### Data Protection
- All processing on-device
- No network requests for transcription
- No analytics or tracking
- No third-party services
- Files encrypted by iOS

### Permissions Required
- Microphone (recording)
- No location access
- No contact access
- No camera access

---

## Future Considerations

### Scalability Options
1. Server-side processing for large models
2. iCloud sync between devices
3. Watch app for quick recording
4. Mac Catalyst version
5. Widgets for quick access

### Potential Features
- Meeting summaries (AI-generated)
- Action item extraction
- Keyword search within transcripts
- Voice commands
- Custom vocabulary training
- Team collaboration features

---

## Success Metrics

### MVP Success Criteria
- [ ] Record 1-hour meeting successfully
- [ ] Transcribe with >80% accuracy
- [ ] Process 1-hour audio in <15 minutes
- [ ] Share files without data loss
- [ ] Maintain recordings after app deletion/reinstall

### User Experience Goals
- First recording within 30 seconds of install
- Zero crashes during recording
- Intuitive UI requiring no tutorial
- Reliable background processing

---

