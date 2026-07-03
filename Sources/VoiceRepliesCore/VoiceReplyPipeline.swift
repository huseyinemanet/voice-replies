import Foundation

public struct VoiceReplyResult {
    public let transcript: String
    public let reply: String
}

public final class VoiceReplyPipeline {
    private let transcriptionService: TranscriptionService
    private let rewriteService: DeepSeekRewriteService

    public init(
        transcriptionService: TranscriptionService = TranscriptionService(),
        rewriteService: DeepSeekRewriteService = DeepSeekRewriteService()
    ) {
        self.transcriptionService = transcriptionService
        self.rewriteService = rewriteService
    }

    public func process(
        audioURL: URL,
        settings: AppSettings,
        deepSeekAPIKey: String,
        transcriptionAPIKey: String,
        maximumUploadBytes: UInt64
    ) async throws -> VoiceReplyResult {
        guard fileSize(for: audioURL) <= maximumUploadBytes else {
            throw VoiceReplyError.audioFileTooLarge
        }

        let transcript = try await transcriptionService.transcribeAudio(
            fileURL: audioURL,
            apiKey: transcriptionAPIKey,
            speechLanguage: settings.speechLanguage
        )

        guard !Self.isLikelyEmptyTranscript(transcript) else {
            throw VoiceReplyError.noSpeechDetected
        }

        let reply = try await rewriteService.rewrite(
            turkishText: transcript,
            tone: settings.tone,
            outputVariant: settings.outputVariant,
            contextPrompt: settings.contextPrompt,
            apiKey: deepSeekAPIKey
        )

        return VoiceReplyResult(transcript: transcript, reply: reply)
    }

    public static func isLikelyEmptyTranscript(_ text: String) -> Bool {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let collapsed = normalized
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let knownEmptyOutputs = [
            "subtitles: m.k.",
            "subtitles: m.k",
            "subtitle: m.k.",
            "subtitle: m.k",
            "altyazı m.k.",
            "altyazı m.k",
            "izlediğiniz için teşekkürler.",
            "izlediğiniz için teşekkürler",
            "abone olmayı unutmayın.",
            "abone olmayı unutmayın"
        ]

        return collapsed.isEmpty || knownEmptyOutputs.contains(collapsed)
    }

    private func fileSize(for url: URL) -> UInt64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? UInt64 ?? 0
    }
}
