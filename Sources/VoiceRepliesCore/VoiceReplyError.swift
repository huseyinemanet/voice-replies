import Foundation

public enum VoiceReplyError: LocalizedError {
    case missingAPIKey(String)
    case recordingFailed
    case noActiveRecording
    case noSpeechDetected
    case inputDeviceChanged
    case speechRecognitionPermissionDenied
    case speechRecognitionUnavailable
    case speechRecognitionTimedOut
    case invalidServerResponse
    case requestFailed(String)
    case emptyTranscription
    case emptyModelResponse
    case audioFileTooLarge
    case clipboardWriteFailed(String)
    case keychainFailure(OSStatus)
    case hotKeyRegistrationFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey(let name):
            return "\(name) is missing. Add it in Settings."
        case .recordingFailed:
            return "Recording could not be started."
        case .noActiveRecording:
            return "There is no active recording to stop."
        case .noSpeechDetected:
            return "No speech was detected."
        case .inputDeviceChanged:
            return "The microphone input changed during recording. Please record that reply again."
        case .speechRecognitionPermissionDenied:
            return "Speech recognition access is needed. Enable it in Settings."
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available right now."
        case .speechRecognitionTimedOut:
            return "Speech recognition took too long. Please try again."
        case .invalidServerResponse:
            return "The server response was not valid."
        case .requestFailed(let message):
            return message
        case .emptyTranscription:
            return "The transcription came back empty."
        case .emptyModelResponse:
            return "The translated reply came back empty."
        case .audioFileTooLarge:
            return "The recording is too large to upload. Try a shorter message."
        case .clipboardWriteFailed:
            return "The reply could not be copied to the clipboard."
        case .keychainFailure(let status):
            return "Keychain save failed with status \(status)."
        case .hotKeyRegistrationFailed(let status):
            return "Keyboard shortcut could not be registered. macOS returned status \(status)."
        }
    }
}
