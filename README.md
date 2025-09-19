# 🎙️ Whisper Note

<div align="center">
  
  [![iOS](https://img.shields.io/badge/iOS-16.0+-000000?style=flat&logo=apple&logoColor=white)](https://www.apple.com/ios/)
  [![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=flat&logo=swift&logoColor=white)](https://swift.org/)
  [![WhisperKit](https://img.shields.io/badge/WhisperKit-ML-blue?style=flat)](https://github.com/argmaxinc/WhisperKit)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  
  **On-device meeting transcription for iOS**
  
  Record meetings • Transcribe offline • Keep your privacy
  
</div>

---

## ✨ Features

- 🎤 **High-quality audio recording** - Record meetings, lectures, and conversations
- 🔐 **100% on-device processing** - Your audio never leaves your iPhone
- 🇩🇪 **German language focus** - Optimized for German transcription (more languages coming)
- 💾 **Dual storage** - Keep both original audio and transcripts
- 📤 **Easy sharing** - Export via AirDrop, Email, Messages, and more
- 🚀 **No internet required** - Works completely offline
- 🔋 **Optimized for iPhone 15 Pro** - Efficient processing with Apple Silicon

## 📱 Screenshots

<div align="center">
<table>
  <tr>
    <td><img src="screenshots/recording.png" width="250" alt="Recording Screen"/></td>
    <td><img src="screenshots/library.png" width="250" alt="Library Screen"/></td>
    <td><img src="screenshots/transcript.png" width="250" alt="Transcript View"/></td>
  </tr>
  <tr>
    <td align="center">Recording</td>
    <td align="center">Library</td>
    <td align="center">Transcript</td>
  </tr>
</table>
</div>

## 🚀 Getting Started

### Prerequisites

- iOS 16.0 or later
- Xcode 15.0 or later
- iPhone (iPad compatible)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/whisper-note.git
   cd whisper-note
   ```

2. **Install WhisperKit**
   ```bash
   # WhisperKit will be automatically fetched via Swift Package Manager
   ```

3. **Open in Xcode**
   ```bash
   open WhisperNote.xcodeproj
   ```

4. **Build and Run**
   - Select your target device
   - Press `⌘ + R` to build and run

### First Time Setup

1. Launch the app
2. Grant microphone permission when prompted
3. The Whisper model will download on first use (~250MB)
4. Start recording!

## 📖 Usage

### Recording a Meeting

1. Tap the **Record** tab
2. Press the large record button
3. The app will continue recording even if you switch apps
4. Press stop when finished
5. Your recording is automatically saved

### Generating Transcripts

1. Go to the **Library** tab
2. Find your recording
3. Swipe left and tap **Transcribe**
4. Wait for processing (approximately 10-15 minutes per hour of audio)
5. The transcript will be saved alongside your audio

### Sharing Files

1. Select any recording
2. Swipe left and tap **Share**
3. Choose what to share:
   - Audio only
   - Transcript only
   - Both files
4. Select your sharing method

## 🏗️ Architecture

```
WhisperNote/
├── App/
│   ├── WhisperNoteApp.swift       # App entry point
│   └── AppDelegate.swift          # App lifecycle
├── Views/
│   ├── RecordingView.swift        # Recording interface
│   ├── LibraryView.swift          # File management
│   └── SettingsView.swift         # App settings
├── Models/
│   ├── AudioRecording.swift       # Recording model
│   └── Transcript.swift           # Transcript model
├── Services/
│   ├── AudioRecorder.swift        # Recording service
│   ├── TranscriptionService.swift # WhisperKit integration
│   └── FileManager.swift          # Storage management
└── Resources/
    └── Assets.xcassets             # App assets
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow Swift style guidelines
- Write unit tests for new features
- Update documentation as needed
- Ensure UI works on all supported devices

## 🗺️ Roadmap

### Version 1.0 (Current)
- [x] Basic recording functionality
- [x] WhisperKit integration
- [x] File management
- [x] Sharing capabilities

### Version 1.1 (Planned)
- [ ] Background transcription
- [ ] Translation support (German → English/Korean)
- [ ] Audio trimming
- [ ] Batch processing

### Version 2.0 (Future)
- [ ] Real-time transcription
- [ ] Speaker diarization
- [ ] iCloud sync
- [ ] Mac Catalyst support
- [ ] Server-side processing option

## 📊 Performance

| Audio Duration | Processing Time | Model | Device |
|---------------|-----------------|--------|---------|
| 10 minutes | ~1-2 minutes | Small | iPhone 15 Pro |
| 30 minutes | ~5-7 minutes | Small | iPhone 15 Pro |
| 60 minutes | ~10-15 minutes | Small | iPhone 15 Pro |

*Performance may vary based on audio quality and background noise*

## 🛡️ Privacy

- **No data collection** - We don't collect any user data
- **No analytics** - No tracking or analytics tools
- **No cloud processing** - All transcription happens on your device
- **No account required** - Use the app without signing up
- **Your data stays yours** - Full control over your recordings

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [WhisperKit](https://github.com/argmaxinc/WhisperKit) - On-device speech recognition
- [OpenAI Whisper](https://github.com/openai/whisper) - Original Whisper model
- Apple Speech framework documentation
- The open-source community

## 💬 Support

For support, please open an issue in the GitHub repository.

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

---

<div align="center">
  Made with ❤️ for the iOS community
  
  <br>
  
  <a href="https://github.com/yourusername/whisper-note/stargazers">⭐ Star this repo if you find it helpful!</a>
</div>
