# Voice Replies

Voice Replies is a small private macOS menu bar app for turning Turkish voice notes into natural English Slack replies.

Click the menu bar microphone, speak in Turkish, stop the recording, and the app transcribes your speech, rewrites it into casual workplace English, copies the result to your clipboard, and shows a short preview.

## Features

- macOS menu bar app with a microphone icon.
- Global shortcut: `Control + Option + Command + Space`.
- Local microphone recording with macOS permission handling.
- Turkish speech-to-text through OpenAI Whisper.
- Natural British or American English rewriting through DeepSeek.
- Casual Slack-style output for day-to-day workplace replies.
- Automatic clipboard copy after processing.
- macOS notification when allowed, with an in-app toast fallback.
- Local settings screen for API keys, tone, and output variant.
- API keys stored in macOS Keychain.
- Optional login item support, so the app can launch automatically after restart.
- Empty/silent recording guard to avoid bogus transcripts.

## How It Works

1. Start recording from the menu bar icon or the global shortcut.
2. Speak in Turkish.
3. Stop recording from the icon or by pressing the shortcut again.
4. The app transcribes the audio.
5. The Turkish transcript is rewritten into the selected English variant.
6. The final message is copied to the clipboard.
7. A preview appears in a notification or toast.

## Requirements

- macOS 13 or newer.
- Swift 5.9 or newer.
- An OpenAI API key for transcription.
- A DeepSeek API key for rewriting.

## Build

```bash
./scripts/build_app.sh
```

The built app will be created at:

```text
dist/Voice Replies.app
```

Open it with:

```bash
open "dist/Voice Replies.app"
```

## Install Locally

Copy the built app to `/Applications`:

```bash
ditto "dist/Voice Replies.app" "/Applications/Voice Replies.app"
open "/Applications/Voice Replies.app"
```

To launch automatically after restart, add it to macOS Login Items from:

```text
System Settings -> General -> Login Items
```

## Settings

Right-click the menu bar icon and choose **Settings...**.

Add:

- `DEEPSEEK_API_KEY`
- `OPENAI_API_KEY`

The keys are stored in macOS Keychain. Tone and output variant are stored locally in user defaults.

## Output Variants

Voice Replies supports:

- `British English`
- `American English`

The rewrite prompt is tuned for natural workplace chat:

- casual and human,
- not robotic,
- not overly corporate,
- matched to the selected English variant,
- no added information,
- no em dashes or en dashes,
- short and careful when the input is unclear.

## Privacy

Voice Replies has no backend of its own. Audio is recorded to a temporary local `.m4a` file, sent to the configured transcription provider, then removed after processing. The Turkish transcript is sent to DeepSeek for rewriting.

API keys remain local in macOS Keychain.

## Project Structure

```text
Sources/VoiceTranslation/   Swift app source
Resources/Info.plist        macOS bundle metadata
scripts/build_app.sh        Release build and app bundle script
Package.swift               Swift package definition
```

## Known Missing Piece

- The app does not have a dedicated app icon yet. It currently relies on the menu bar status icon only.

## License

MIT License. See [LICENSE](LICENSE).
