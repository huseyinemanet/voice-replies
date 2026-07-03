import AVFoundation
import Foundation
#if canImport(VoiceRepliesCore)
import VoiceRepliesCore
#endif

struct iOSRecordedAudio {
    let url: URL
    let containsSpeech: Bool
    let duration: TimeInterval
    let fileSize: UInt64
}

final class iOSAudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var audioURL: URL?
    private var startedAt: Date?
    private var meteringTimer: Timer?
    private var speechLikeSampleCount = 0

    func ensureMicrophonePermission() async -> Bool {
        let session = AVAudioSession.sharedInstance()

        switch session.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    func start() throws -> URL {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice-reply-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw VoiceReplyError.recordingFailed
        }

        self.recorder = recorder
        self.audioURL = url
        startedAt = Date()
        speechLikeSampleCount = 0
        startMetering(recorder: recorder)
        return url
    }

    func stop() throws -> iOSRecordedAudio {
        guard let recorder, let audioURL else {
            throw VoiceReplyError.noActiveRecording
        }

        updateSpeechDetection(from: recorder)
        let duration = startedAt.map { Date().timeIntervalSince($0) } ?? recorder.currentTime
        recorder.stop()
        cleanup()

        let attributes = try? FileManager.default.attributesOfItem(atPath: audioURL.path)
        let fileSize = attributes?[.size] as? UInt64 ?? 0

        return iOSRecordedAudio(
            url: audioURL,
            containsSpeech: speechLikeSampleCount >= 2 && duration >= 0.35,
            duration: duration,
            fileSize: fileSize
        )
    }

    func cancel() -> URL? {
        let currentURL = audioURL
        recorder?.stop()
        cleanup()
        return currentURL
    }

    private func startMetering(recorder: AVAudioRecorder) {
        meteringTimer?.invalidate()
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, weak recorder] _ in
            guard let self, let recorder else { return }
            updateSpeechDetection(from: recorder)
        }
    }

    private func updateSpeechDetection(from recorder: AVAudioRecorder) {
        recorder.updateMeters()

        let averagePower = recorder.averagePower(forChannel: 0)
        let peakPower = recorder.peakPower(forChannel: 0)

        if averagePower > -45 || peakPower > -30 {
            speechLikeSampleCount += 1
        }
    }

    private func cleanup() {
        meteringTimer?.invalidate()
        meteringTimer = nil
        recorder = nil
        audioURL = nil
        startedAt = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
