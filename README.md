# Voice Replies

Voice Replies is a private macOS and iOS productivity app for turning spoken Turkish into natural English replies for Slack and everyday workplace chat.

The flow is simple: record your voice, transcribe it, rewrite it with the chosen tone and English variant, copy the final message to the clipboard, and show a short notification when it is ready.

## What It Does

- Records Turkish voice replies on macOS or iPhone.
- Transcribes speech with OpenAI Whisper.
- Rewrites the transcript with DeepSeek.
- Outputs natural British or American English.
- Copies the final reply to the clipboard automatically.
- Shows copied feedback with the translated text.
- Keeps optional local clipboard history for quick reuse.
- Stores provider keys locally in Keychain.

This project is built for personal use. It is not intended as a public SaaS, backend service, or App Store product.

## Platforms

### macOS

The macOS app runs as a menu bar utility.

- Menu bar microphone icon.
- Global keyboard shortcut for start and stop.
- Recording, processing, copied, and error states.
- Clipboard history from the menu bar.
- Settings window for keys, tone, output variant, context prompt, shortcut, history, and launch at login.
- macOS notification with a local toast fallback.
- Optional launch at login.

### iOS

The iOS app is a small SwiftUI companion app for personal installation from Xcode.

- Large microphone button on the main screen.
- Tap once to record, tap again to stop and translate.
- Idle ripple animation behind the microphone button.
- Recording pulse animation.
- Processing spinner animation.
- Automatic clipboard copy through `UIPasteboard`.
- Local notification when the reply is copied.
- History screen with tap to copy, swipe to delete, and clear confirmation.
- Settings screen for API keys, tone, output variant, speech language, context prompt, and history.
- Home screen quick actions for recent replies.

## Translation Behaviour

Voice Replies is designed for a Turkish-speaking person replying in workplace chat. The rewrite prompt aims to:

- sound natural and conversational
- avoid robotic phrasing
- preserve intent and directness
- avoid adding extra information
- avoid long dash punctuation
- keep short replies short
- follow the selected tone: casual, neutral, or polished
- follow the selected output variant: British English or American English
- use the optional context prompt when provided

## API Keys

You need:

- `DEEPSEEK_API_KEY`
- OpenAI transcription API key

Both are stored locally in Keychain. They are entered from the app settings screens.

## Privacy

Voice Replies has no backend of its own.

- API keys are stored in Keychain.
- Settings are stored locally on the device.
- Clipboard history is optional and local.
- Temporary audio files are removed after processing.
- Transcript history is not intentionally stored.
- Audio is sent to OpenAI for transcription.
- The transcript is sent to DeepSeek for rewriting.

Disable clipboard history in Settings if you do not want recent replies stored locally.

## Project Structure

```text
VoiceReplies.xcodeproj             Xcode project with macOS and iOS targets
Package.swift                      SwiftPM support for shared core and macOS builds
Resources/Info.plist               macOS app metadata
Resources/AppIcon.icns             macOS app icon
Resources/iOS/Info.plist           iOS app metadata
Resources/iOS/Assets.xcassets/     iOS app icon assets
Sources/VoiceRepliesCore/          Shared business logic
Sources/VoiceRepliesMac/           macOS menu bar app
Sources/VoiceRepliesiOS/           iOS SwiftUI app
Tests/VoiceTranslationTests/       Unit tests
scripts/build_app.sh               Local macOS app bundle build
scripts/package_release.sh         Release packaging helper
```

## Shared Core

Shared logic lives in `Sources/VoiceRepliesCore`:

- settings model
- output variant and tone model
- prompt and rewrite pipeline
- transcription service
- DeepSeek API client
- retry and HTTP validation
- Keychain storage
- clipboard history storage
- common error handling

Platform-specific UI, permissions, clipboard, notifications, shortcuts, and audio recording stay in the macOS and iOS targets.

## Build

### Requirements

- macOS 13 or later for the macOS app
- Xcode with iOS SDK for the iOS app
- Swift 5.9 or later
- Apple development signing for installing on a physical iPhone

### macOS App Bundle

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

### Xcode

Open:

```text
VoiceReplies.xcodeproj
```

Schemes:

- `Voice Replies macOS`
- `Voice Replies iOS`

To install on iPhone, select the `Voice Replies iOS` scheme, choose the connected device, select a development team, and run.

## Useful Checks

Swift tests:

```bash
swift test
```

macOS build:

```bash
xcodebuild -project VoiceReplies.xcodeproj \
  -scheme "Voice Replies macOS" \
  -configuration Debug \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  build
```

iOS simulator build:

```bash
xcodebuild -project VoiceReplies.xcodeproj \
  -scheme "Voice Replies iOS" \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Version

Current app version: `0.2.0`

## License

Voice Replies is released under the MIT License. See [LICENSE](LICENSE).
