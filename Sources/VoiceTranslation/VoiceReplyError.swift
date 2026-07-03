import Foundation

enum VoiceReplyError: LocalizedError {
    case missingAPIKey(String)
    case recordingFailed
    case noActiveRecording
    case noSpeechDetected
    case invalidServerResponse
    case requestFailed(String)
    case emptyTranscription
    case emptyModelResponse
    case keychainFailure(OSStatus)
    case hotKeyRegistrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let name):
            return "\(name) is missing. Add it in Settings."
        case .recordingFailed:
            return "Recording could not be started."
        case .noActiveRecording:
            return "There is no active recording to stop."
        case .noSpeechDetected:
            return "No speech was detected."
        case .invalidServerResponse:
            return "The server response was not valid."
        case .requestFailed(let message):
            return message
        case .emptyTranscription:
            return "The transcription came back empty."
        case .emptyModelResponse:
            return "The translated reply came back empty."
        case .keychainFailure(let status):
            return "Keychain save failed with status \(status)."
        case .hotKeyRegistrationFailed(let status):
            return "Keyboard shortcut could not be registered. macOS returned status \(status)."
        }
    }
}
