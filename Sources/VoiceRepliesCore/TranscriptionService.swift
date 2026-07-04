import Foundation
import Speech

public final class TranscriptionService {
    public init() {}

    public func transcribeAudio(
        fileURL: URL,
        speechLanguage: SpeechLanguage
    ) async throws -> String {
        guard await requestSpeechRecognitionPermission() else {
            throw VoiceReplyError.speechRecognitionPermissionDenied
        }

        let locale = Locale(identifier: speechLanguage.localeIdentifier)
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw VoiceReplyError.speechRecognitionUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = false
        request.contextualStrings = speechLanguage.contextualTerms

        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        let transcript = try await recognize(request: request, recognizer: recognizer)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !transcript.isEmpty else {
            throw VoiceReplyError.emptyTranscription
        }

        return transcript
    }

    public func transcribeTurkishAudio(fileURL: URL) async throws -> String {
        try await transcribeAudio(fileURL: fileURL, speechLanguage: .turkish)
    }

    private func requestSpeechRecognitionPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func recognize(
        request: SFSpeechURLRecognitionRequest,
        recognizer: SFSpeechRecognizer
    ) async throws -> String {
        let lock = NSLock()
        var didResume = false
        var task: SFSpeechRecognitionTask?
        var continuation: CheckedContinuation<String, Error>?

        func resumeOnce(_ result: Result<String, Error>) {
            lock.lock()
            defer { lock.unlock() }

            guard !didResume else { return }
            didResume = true
            task?.cancel()

            switch result {
            case .success(let transcript):
                continuation?.resume(returning: transcript)
            case .failure(let error):
                continuation?.resume(throwing: error)
            }
        }

        return try await withCheckedThrowingContinuation { checkedContinuation in
            continuation = checkedContinuation
            task = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    resumeOnce(.failure(error))
                    return
                }

                guard let result, result.isFinal else { return }
                resumeOnce(.success(result.bestTranscription.formattedString))
            }
        }
    }
}
