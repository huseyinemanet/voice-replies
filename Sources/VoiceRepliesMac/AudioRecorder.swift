import AVFoundation
import Foundation
#if canImport(VoiceRepliesCore)
import VoiceRepliesCore
#endif

struct RecordedAudio {
    let url: URL
    let containsSpeech: Bool
    let duration: TimeInterval
    let fileSize: UInt64
}

final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var onInputDeviceChanged: (() -> Void)?

    private var recorder: AVAudioRecorder?
    private var audioURL: URL?
    private var startedAt: Date?
    private var meteringTimer: Timer?
    private var speechLikeSampleCount = 0
    private var sampleCount = 0

    func ensureMicrophonePermission() async throws -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func start() throws -> URL {
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
        sampleCount = 0
        startMetering(recorder: recorder)
        startDeviceChangeObservation()
        return url
    }

    func stop() throws -> RecordedAudio {
        guard let recorder, let audioURL else {
            throw VoiceReplyError.noActiveRecording
        }

        updateSpeechDetection(from: recorder)
        let duration = startedAt.map { Date().timeIntervalSince($0) } ?? recorder.currentTime
        recorder.stop()
        cleanupRecorderState()

        let attributes = try? FileManager.default.attributesOfItem(atPath: audioURL.path)
        let fileSize = attributes?[.size] as? UInt64 ?? 0

        return RecordedAudio(
            url: audioURL,
            containsSpeech: speechLikeSampleCount >= 2 && duration >= 0.35,
            duration: duration,
            fileSize: fileSize
        )
    }

    func cancel() -> URL? {
        let currentURL = audioURL
        recorder?.stop()
        cleanupRecorderState()
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
        sampleCount += 1

        let averagePower = recorder.averagePower(forChannel: 0)
        let peakPower = recorder.peakPower(forChannel: 0)

        if averagePower > -45 || peakPower > -30 {
            speechLikeSampleCount += 1
        }
    }

    private func startDeviceChangeObservation() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(audioInputDeviceChanged),
            name: AVCaptureDevice.wasConnectedNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(audioInputDeviceChanged),
            name: AVCaptureDevice.wasDisconnectedNotification,
            object: nil
        )
    }

    private func cleanupRecorderState() {
        NotificationCenter.default.removeObserver(self, name: AVCaptureDevice.wasConnectedNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVCaptureDevice.wasDisconnectedNotification, object: nil)
        meteringTimer?.invalidate()
        meteringTimer = nil
        recorder = nil
        audioURL = nil
        startedAt = nil
    }

    @objc private func audioInputDeviceChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.onInputDeviceChanged?()
        }
    }
}
