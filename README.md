# Voice Replies

Voice Replies is a private macOS menu bar app for turning spoken Turkish into natural Slack-ready English replies.

Click the microphone icon or press your global shortcut, speak, stop recording, and the app will:

1. transcribe your Turkish voice note,
2. rewrite it with DeepSeek,
3. copy the final English reply to the clipboard,
4. show a notification or local toast with a preview.

## Current Version

`0.2.0`

## Highlights

- Native macOS menu bar app.
- Dedicated app icon.
- Global start/stop shortcut with selectable presets.
- OpenAI Whisper transcription with Turkish plus mixed English technical-term hints.
- DeepSeek rewrite into natural workplace English.
- British English and American English output variants.
- Casual, neutral, and polished tones.
- Optional context prompt for role, domain, style, or wording guidance.
- Clipboard history menu for the latest 20 copied replies.
- Privacy switch to disable and clear clipboard history.
- Launch at Login setting.
- macOS notification when allowed, in-app toast fallback when notifications are disabled.
- Clipboard failure fallback window with the full translated reply.
- API keys stored in macOS Keychain.

## How To Use

1. Open `Voice Replies.app`.
2. Right-click the menu bar icon and choose **Settings...**.
3. Add your `DEEPSEEK_API_KEY` and `OPENAI_API_KEY`.
4. Choose tone, English variant, shortcut, history preference, and Launch at Login.
5. Press the shortcut or left-click the menu bar icon to start recording.
6. Speak your reply.
7. Press the shortcut or click again to stop.
8. Paste the copied English message into Slack.

If either API key is missing, recording will not start. The app opens Settings and shows a short message instead.

## Settings

The Settings window includes:

- `DeepSeek API Key`: rewrite and translation key.
- `Transcription API Key`: OpenAI key used for speech-to-text.
- `Tone`: `casual`, `neutral`, or `polished`.
- `Output Variant`: `British English` or `American English`.
- `Context Prompt`: optional role, style, domain, or wording guidance.
- `Keyboard Shortcut`: choose one of the preset global shortcuts.
- `Clipboard History`: keep or disable local history.
- `Launch at Login`: start the app automatically after restart.

You can leave the context prompt empty. If you add guidance, it is included in the rewrite prompt without replacing the main rule: return only the final Slack-ready English message.

## Clipboard History

Right-click the menu bar icon and open **Clipboard History**.

- Keeps the latest 20 successful replies.
- Shows a short preview and creation time.
- Click any item to copy it again.
- Use **Clear History** to remove stored replies.
- Disable **Clipboard History** in Settings to stop saving replies and clear existing history.

History is local only and stored in user defaults.

## Reliability Guards

Voice Replies handles the main edge cases for day-to-day use:

- Microphone permission denied: recording does not start and the user is told what to enable.
- Missing API keys: recording does not start and Settings opens.
- Empty or silent recording: nothing is copied.
- Very short recording: treated as no speech unless real audio is detected.
- Long recording: automatically stops and processes at 10 minutes.
- Oversized audio file: upload is blocked before transcription.
- Processing state: new recording cannot start until the current job finishes.
- Rapid repeated clicks: duplicate start/stop actions are ignored.
- Input device change during recording: recording is cancelled cleanly and the user is asked to try again.
- Transient network/API errors: timeout, rate limit, and server errors are retried briefly.
- Clipboard write failure: previous clipboard is restored when possible and the full reply is shown in a fallback window.
- Stale temporary audio: leftover `voice-reply-*.m4a` files are removed on next launch.

## Output Style

The rewrite prompt is tuned for:

- natural workplace chat,
- Slack-friendly wording,
- conversational language,
- no robotic phrasing,
- no extra information,
- no em dashes or en dashes,
- concise handling of unclear input,
- British or American English based on the selected variant.

## Privacy

Voice Replies has no backend of its own.

Local data:

- API keys are stored in macOS Keychain.
- Tone, output variant, shortcut, context prompt, Launch at Login preference, and history preference are stored locally.
- Clipboard history is optional and local.
- Temporary audio files are removed after processing.
- Transcript history is not intentionally stored.
- API keys, transcripts, and Slack message content are not intentionally logged.

Network calls:

- Audio is sent to OpenAI for transcription.
- The transcript is sent to DeepSeek for rewriting.

## Build

Requirements:

- macOS 13 or newer.
- Swift 5.9 or newer.

Build the app:

```bash
./scripts/build_app.sh
```

The app bundle is created at:

```text
dist/Voice Replies.app
```

Open it:

```bash
open "dist/Voice Replies.app"
```

Install locally:

```bash
ditto "dist/Voice Replies.app" "/Applications/Voice Replies.app"
open "/Applications/Voice Replies.app"
```

## Release Packaging

Create a local zip:

```bash
./scripts/package_release.sh
```

For Developer ID signing and notarization, provide:

```bash
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)" \
APPLE_ID="you@example.com" \
APPLE_TEAM_ID="TEAMID" \
APPLE_APP_SPECIFIC_PASSWORD="app-specific-password" \
./scripts/package_release.sh
```

Without those values, the script keeps the local ad-hoc signature and skips notarization.

## Checks

Release build:

```bash
swift build -c release
```

Tests are included under `Tests/VoiceTranslationTests` and run in GitHub Actions on macOS with Xcode:

```bash
swift test
```

On machines with only Apple Command Line Tools installed, local `swift test` may not have access to `XCTest`. The app build still works with the Command Line Tools.

## Project Structure

```text
.github/workflows/ci.yml        GitHub Actions build and test workflow
Package.swift                   Swift package definition
Resources/AppIcon.icns          macOS app icon
Resources/Info.plist            macOS bundle metadata
Sources/VoiceTranslation/       App source code
Tests/VoiceTranslationTests/    Unit tests for local settings/history logic
scripts/build_app.sh            Local app bundle build script
scripts/package_release.sh      Zip, signing, and notarization helper
```

## Releases

GitHub Releases:

https://github.com/huseyinemanet/voice-replies/releases

## License

MIT License. See [LICENSE](LICENSE).
