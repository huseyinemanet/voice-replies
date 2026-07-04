import Foundation
import XCTest
@testable import VoiceRepliesCore

final class VoiceReplyPipelineTests: XCTestCase {
    private var audioURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("VoiceReplyPipelineTests-\(UUID().uuidString).m4a")
        try Data("audio".utf8).write(to: audioURL)
    }

    override func tearDownWithError() throws {
        if let audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        audioURL = nil
        try super.tearDownWithError()
    }

    func testProcessReturnsTranscriptAndReply() async throws {
        let pipeline = VoiceReplyPipeline(
            transcriptionService: MockTranscriber(result: .success("Merhaba, bunu biraz daha sade yazabilir miyiz?")),
            rewriteService: MockRewriter(result: .success("Hey, could we make this a bit simpler?"))
        )

        let result = try await pipeline.process(
            audioURL: audioURL,
            settings: AppSettings(),
            deepSeekAPIKey: "deepseek-key",
            maximumUploadBytes: 1024
        )

        XCTAssertEqual(result.transcript, "Merhaba, bunu biraz daha sade yazabilir miyiz?")
        XCTAssertEqual(result.reply, "Hey, could we make this a bit simpler?")
    }

    func testProcessTreatsKnownEmptyTranscriptionAsNoSpeech() async throws {
        let pipeline = VoiceReplyPipeline(
            transcriptionService: MockTranscriber(result: .success("Subtitles: M.K.")),
            rewriteService: MockRewriter(result: .success("Should not be used"))
        )

        do {
            _ = try await pipeline.process(
                audioURL: audioURL,
                settings: AppSettings(),
                deepSeekAPIKey: "deepseek-key",
                maximumUploadBytes: 1024
            )
            XCTFail("Expected noSpeechDetected")
        } catch VoiceReplyError.noSpeechDetected {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessTreatsBlankTranscriptionAsNoSpeech() async throws {
        let pipeline = VoiceReplyPipeline(
            transcriptionService: MockTranscriber(result: .success(" \n ")),
            rewriteService: MockRewriter(result: .success("Should not be used"))
        )

        do {
            _ = try await pipeline.process(
                audioURL: audioURL,
                settings: AppSettings(),
                deepSeekAPIKey: "deepseek-key",
                maximumUploadBytes: 1024
            )
            XCTFail("Expected noSpeechDetected")
        } catch VoiceReplyError.noSpeechDetected {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessSurfacesRewriteFailure() async throws {
        let pipeline = VoiceReplyPipeline(
            transcriptionService: MockTranscriber(result: .success("Bunu sonra konuşalım.")),
            rewriteService: MockRewriter(result: .failure(MockError.rewriteFailed))
        )

        do {
            _ = try await pipeline.process(
                audioURL: audioURL,
                settings: AppSettings(),
                deepSeekAPIKey: "deepseek-key",
                maximumUploadBytes: 1024
            )
            XCTFail("Expected rewrite failure")
        } catch MockError.rewriteFailed {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private struct MockTranscriber: AudioTranscribing {
    let result: Result<String, Error>

    func transcribeAudio(
        fileURL: URL,
        speechLanguage: SpeechLanguage
    ) async throws -> String {
        try result.get()
    }
}

private struct MockRewriter: ReplyRewriting {
    let result: Result<String, Error>

    func rewrite(
        turkishText: String,
        tone: ReplyTone,
        outputVariant: OutputVariant,
        contextPrompt: String,
        apiKey: String
    ) async throws -> String {
        try result.get()
    }
}

private enum MockError: Error {
    case rewriteFailed
}
