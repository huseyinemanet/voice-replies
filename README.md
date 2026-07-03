# Voice Replies

Voice Replies is a private macOS menu bar app for turning Turkish speech into natural Slack-ready English replies.

Press the shortcut, speak in Turkish, press it again, and Voice Replies transcribes the audio, rewrites it into the selected English variant, copies the final message to the clipboard, and shows a short preview.

## Current Version

`0.1.1`

## What It Does

- Records from the macOS menu bar.
- Uses `Control + Option + Command + Space` as a global start/stop shortcut.
- Transcribes Turkish audio with OpenAI Whisper.
- Rewrites the transcript with DeepSeek.
- Supports `British English` and `American English` output.
- Supports `casual`, `neutral`, and `polished` tone.
- Copies the final reply to the clipboard.
- Keeps the last 20 copied replies in local clipboard history.
- Shows a macOS notification when allowed.
- Falls back to an in-app toast when notifications are disabled.
- Stores API keys in macOS Keychain.
- Keeps settings local on the Mac.

## Use

1. Open `Voice Replies.app`.
2. Right-click the menu bar icon and open **Settings...**.
3. Add your `DEEPSEEK_API_KEY` and `OPENAI_API_KEY`.
4. Choose tone and output variant.
5. Press `Control + Option + Command + Space` to start recording.
6. Speak in Turkish.
7. Press the shortcut again to stop.
8. Paste the copied English reply into Slack.

You can also left-click the menu bar icon to start and stop recording.

## Clipboard History

Right-click the menu bar icon and open **Clipboard History** to see recent copied replies.

- The app keeps the latest 20 successful replies.
- Each item shows a short preview and the time it was created.
- Click any history item to copy it back to the clipboard.
- Use **Clear History** from the same submenu to remove stored replies.
- History is stored locally in user defaults.

## Settings

The Settings window includes:

- `DeepSeek API Key`: used for rewrite/translation.
- `Transcription API Key`: OpenAI key used for speech-to-text.
- `Tone`: `casual`, `neutral`, or `polished`.
- `Output Variant`: `British English` or `American English`.
- `Keyboard Shortcut`: fixed to `Control + Option + Command + Space`.

Both API keys are required. If either key is missing, the app will not start recording and will open Settings instead.

## Output Style

The rewrite prompt is tuned for natural workplace chat:

- human and conversational,
- suitable for Slack,
- not overly formal,
- not robotic,
- no extra information,
- no em dashes or en dashes,
- careful with unclear or incomplete input,
- matched to the selected British or American English variant.

## Edge-Case Handling

Voice Replies includes guards for common failure cases:

- Microphone permission denied: recording does not start and the user is told to enable access.
- Missing API keys: recording does not start.
- Empty/silent recordings: nothing is copied to the clipboard.
- Very short recordings: treated as no speech when no real audio is detected.
- Oversized audio files: upload is stopped before transcription.
- Processing state: recording cannot be started again while transcription/rewrite is running.
- Rapid repeated clicks: duplicate start/stop actions are ignored.
- API errors: user-facing messages are short and do not expose raw API responses.
- Clipboard write failure: the app tries to restore the previous clipboard text and shows the result preview.
- Crash leftovers: stale temporary `voice-reply-*.m4a` files are cleaned on next launch.

## Privacy

Voice Replies has no backend of its own.

Local behaviour:

- API keys are stored in macOS Keychain.
- Tone and output variant are stored in local user defaults.
- Clipboard history is stored locally in user defaults.
- Audio is recorded to a temporary `.m4a` file.
- Temporary audio is removed after processing.
- Leftover temporary recordings are removed on next launch.
- The app does not keep transcript history.
- The app does not intentionally log API keys, transcripts, or Slack message content.

Network behaviour:

- Audio is sent to OpenAI for transcription.
- The Turkish transcript is sent to DeepSeek for rewriting.

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

## Install Locally

Copy the built app to `/Applications`:

```bash
ditto "dist/Voice Replies.app" "/Applications/Voice Replies.app"
open "/Applications/Voice Replies.app"
```

To launch automatically after restart, add it from:

```text
System Settings -> General -> Login Items
```

## Releases

Download builds from GitHub Releases:

https://github.com/huseyinemanet/voice-replies/releases

## Project Structure

```text
Package.swift               Swift package definition
Resources/Info.plist        macOS bundle metadata
Sources/VoiceTranslation/   App source code
scripts/build_app.sh        Release build and app bundle script
```

## Known Missing Piece

- The app does not have a dedicated macOS app icon yet. Tracked in issue #1.

## License

MIT License. See [LICENSE](LICENSE).
