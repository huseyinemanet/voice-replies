# Voice Replies

Voice Replies is a private macOS and iOS tool for turning spoken Turkish into natural Slack-ready English replies.

The shared pipeline records audio, transcribes it with OpenAI Whisper, rewrites it with DeepSeek, copies the final English message to the clipboard, and shows feedback.

## Current Version

`0.2.0`

## Apps

### macOS

- Native menu bar app.
- Global start/stop shortcut with selectable presets.
- Clipboard history in the menu bar and Dock recent menu.
- macOS notifications with toast fallback.
- Launch at Login support.
- Existing recording, processing, clipboard, and settings behaviour is preserved.

### iOS

- Simple SwiftUI app target.
- Hold the large microphone button to record.
- Release to stop, transcribe, rewrite, and copy.
- Shows `Copied` feedback and a short preview of the last reply.
- Settings screen for API keys, tone, output variant, speech language, context prompt, and history.

The iOS app is intended for personal installation from Xcode, not App Store distribution.

## Shared Core

Common code lives in `Sources/VoiceRepliesCore`:

- `AppSettings`
- `SpeechLanguage`
- `DeepSeekRewriteService`
- `TranscriptionService`
- `VoiceReplyPipeline`
- `VoiceReplyError`
- `KeychainStore`
- `ClipboardHistoryStore`
- HTTP validation and retry handling

Platform-specific code stays separate:

- `Sources/VoiceRepliesMac`
- `Sources/VoiceRepliesiOS`

## Settings

Both platforms use local settings and Keychain:

- `DeepSeek API Key`
- `Transcription API Key`
- `Tone`: casual, neutral, polished
- `Output Variant`: British English or American English
- `Speech Language`: Turkish
- `Context Prompt`
- `Clipboard History`

macOS also includes:

- `Keyboard Shortcut`
- `Launch at Login`

## Privacy

Voice Replies has no backend of its own.

- API keys are stored in Keychain.
- Settings are stored locally.
- Clipboard history is optional and local.
- Temporary audio files are removed after processing.
- Transcript history is not intentionally stored.
- Audio is sent to OpenAI for transcription.
- The transcript is sent to DeepSeek for rewriting.

## Build

### macOS local bundle

This path works with Apple Command Line Tools:

```bash
./scripts/build_app.sh
```

The app bundle is created at:

```text
dist/Voice Replies.app
```

Install locally:

```bash
ditto "dist/Voice Replies.app" "/Applications/Voice Replies.app"
open "/Applications/Voice Replies.app"
```

### Xcode project

Open:

```text
VoiceReplies.xcodeproj
```

Schemes:

- `Voice Replies macOS`
- `Voice Replies iOS`

The iOS target requires full Xcode with an iOS SDK. This machine currently has only Command Line Tools, so iOS builds are verified through GitHub Actions or on a Mac with Xcode installed.

## Checks

SwiftPM macOS build:

```bash
swift build -c release
```

SwiftPM tests:

```bash
swift test
```

Xcode target builds:

```bash
xcodebuild -project VoiceReplies.xcodeproj -scheme "Voice Replies macOS" -configuration Release -destination "platform=macOS" CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VoiceReplies.xcodeproj -scheme "Voice Replies iOS" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build
```

## Project Structure

```text
VoiceReplies.xcodeproj             Xcode project with macOS and iOS schemes
Package.swift                      SwiftPM support for core + macOS app
Resources/Info.plist               macOS bundle metadata
Resources/iOS/Info.plist           iOS bundle metadata
Resources/AppIcon.icns             macOS app icon
Sources/VoiceRepliesCore/          Shared business logic
Sources/VoiceRepliesMac/           macOS app code
Sources/VoiceRepliesiOS/           iOS app code
Tests/VoiceTranslationTests/       Core unit tests
scripts/build_app.sh               Local macOS bundle build
scripts/package_release.sh         Zip, signing, and notarization helper
```

## Releases

GitHub Releases:

https://github.com/huseyinemanet/voice-replies/releases

## License

MIT License. See [LICENSE](LICENSE).
