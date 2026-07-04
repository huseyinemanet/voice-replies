import Foundation
import Speech

public protocol AudioTranscribing {
    func transcribeAudio(
        fileURL: URL,
        speechLanguage: SpeechLanguage
    ) async throws -> String
}

public final class TranscriptionService: AudioTranscribing {
    private let timeoutNanoseconds: UInt64

    public init(timeoutSeconds: TimeInterval = 60) {
        timeoutNanoseconds = UInt64(max(timeoutSeconds, 1) * 1_000_000_000)
    }

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

        let transcript = try await withRecognitionTimeout { [self] in
            try await self.recognize(request: request, recognizer: recognizer)
        }
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

    private func withRecognitionTimeout(
        _ operation: @escaping @Sendable () async throws -> String
    ) async throws -> String {
        try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask { [timeoutNanoseconds] in
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
                throw VoiceReplyError.speechRecognitionTimedOut
            }

            guard let result = try await group.next() else {
                throw VoiceReplyError.speechRecognitionUnavailable
            }

            group.cancelAll()
            return result
        }
    }

    private func recognize(
        request: SFSpeechURLRecognitionRequest,
        recognizer: SFSpeechRecognizer
    ) async throws -> String {
        let session = SpeechRecognitionSession()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                session.setContinuation(continuation)
                let task = recognizer.recognitionTask(with: request) { result, error in
                    if let error {
                        session.finish(.failure(error))
                        return
                    }

                    guard let result, result.isFinal else { return }
                    session.finish(.success(result.bestTranscription.formattedString))
                }
                session.setTask(task)
            }
        } onCancel: {
            session.cancel()
        }
    }
}

private final class SpeechRecognitionSession: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<String, Error>?
    private var task: SFSpeechRecognitionTask?
    private var didFinish = false

    func setContinuation(_ continuation: CheckedContinuation<String, Error>) {
        lock.lock()
        self.continuation = continuation
        lock.unlock()
    }

    func setTask(_ task: SFSpeechRecognitionTask) {
        lock.lock()
        self.task = task
        let shouldCancel = didFinish
        lock.unlock()

        if shouldCancel {
            task.cancel()
        }
    }

    func finish(_ result: Result<String, Error>) {
        let continuationToResume: CheckedContinuation<String, Error>?
        let taskToCancel: SFSpeechRecognitionTask?

        lock.lock()
        guard !didFinish else {
            lock.unlock()
            return
        }
        didFinish = true
        continuationToResume = continuation
        taskToCancel = task
        continuation = nil
        task = nil
        lock.unlock()

        taskToCancel?.cancel()

        switch result {
        case .success(let transcript):
            continuationToResume?.resume(returning: transcript)
        case .failure(let error):
            continuationToResume?.resume(throwing: error)
        }
    }

    func cancel() {
        finish(.failure(CancellationError()))
    }
}
