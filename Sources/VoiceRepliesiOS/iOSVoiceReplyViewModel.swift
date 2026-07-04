import Combine
import Foundation
import UIKit
#if canImport(VoiceRepliesCore)
import VoiceRepliesCore
#endif

@MainActor
final class iOSVoiceReplyViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case processing
        case copied
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var statusText = "Tap to speak"
    @Published private(set) var lastReply = ""

    private let recorder = iOSAudioRecorder()
    private let pipeline = VoiceReplyPipeline()
    private let maximumTranscriptionUploadBytes: UInt64 = 24 * 1024 * 1024
    private var isStartingRecording = false

    var isRecording: Bool {
        state == .recording
    }

    var isProcessing: Bool {
        state == .processing
    }

    func handleShortcutURL(_ url: URL) {
        guard url.scheme?.lowercased() == "voicereplies" else { return }

        let action = (url.host ?? url.path)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()

        switch action {
        case "record", "start", "start-recording":
            startRecording()
        case "toggle", "toggle-recording":
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        default:
            break
        }
    }

    func startRecording() {
        guard !isStartingRecording, state == .idle || state == .copied || isFailureState else { return }
        isStartingRecording = true

        Task {
            defer {
                isStartingRecording = false
            }

            do {
                guard hasRequiredAPIKeys() else {
                    setFailure("Add API keys in Settings.")
                    return
                }

                guard await recorder.ensureMicrophonePermission() else {
                    setFailure("Microphone access is off.")
                    return
                }

                _ = try recorder.start()
                state = .recording
                statusText = "Listening..."
            } catch {
                setFailure(error.localizedDescription)
            }
        }
    }

    func stopRecording() {
        guard state == .recording else { return }

        do {
            let recordedAudio = try recorder.stop()

            guard recordedAudio.containsSpeech else {
                try? FileManager.default.removeItem(at: recordedAudio.url)
                setFailure("No speech detected.")
                return
            }

            state = .processing
            statusText = "Translating..."
            process(audioURL: recordedAudio.url)
        } catch {
            setFailure(error.localizedDescription)
        }
    }

    func cancelRecording() {
        if let url = recorder.cancel() {
            try? FileManager.default.removeItem(at: url)
        }
        state = .idle
        statusText = "Tap to speak"
    }

    func copyReplyFromHistory(_ text: String) {
        do {
            try copyToClipboard(text)
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            ClipboardHistoryStore.shared.add(trimmedText)
            iOSQuickActionManager.shared.refresh()
            iOSNotificationPresenter.shared.showCopiedNotification(reply: trimmedText)
            lastReply = trimmedText
            state = .copied
            statusText = "Copied from history"
        } catch {
            setFailure(error.localizedDescription)
        }
    }

    private var isFailureState: Bool {
        if case .failed = state {
            return true
        }
        return false
    }

    private func process(audioURL: URL) {
        Task {
            defer {
                try? FileManager.default.removeItem(at: audioURL)
            }

            do {
                let settings = AppSettings.load()

                guard let deepSeekKey = KeychainStore.shared.read(account: KeychainAccount.deepSeekAPIKey), !deepSeekKey.isEmpty else {
                    throw VoiceReplyError.missingAPIKey("DeepSeek API key")
                }

                let result = try await pipeline.process(
                    audioURL: audioURL,
                    settings: settings,
                    deepSeekAPIKey: deepSeekKey,
                    maximumUploadBytes: maximumTranscriptionUploadBytes
                )

                try copyToClipboard(result.reply)
                if settings.saveClipboardHistory {
                    ClipboardHistoryStore.shared.add(result.reply)
                    iOSQuickActionManager.shared.refresh()
                }

                lastReply = result.reply
                state = .copied
                statusText = "Copied"
                iOSNotificationPresenter.shared.showCopiedNotification(reply: result.reply)
            } catch {
                setFailure(error.localizedDescription)
            }
        }
    }

    private func hasRequiredAPIKeys() -> Bool {
        let deepSeekKey = KeychainStore.shared.read(account: KeychainAccount.deepSeekAPIKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return !deepSeekKey.isEmpty
    }

    private func copyToClipboard(_ text: String) throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw VoiceReplyError.emptyModelResponse
        }

        UIPasteboard.general.string = trimmedText

        guard UIPasteboard.general.string == trimmedText else {
            throw VoiceReplyError.clipboardWriteFailed(trimmedText)
        }
    }

    private func setFailure(_ message: String) {
        state = .failed(message)
        statusText = message
    }
}
