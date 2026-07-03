import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private let recorder = AudioRecorder()
    private let transcriptionService = TranscriptionService()
    private let rewriteService = DeepSeekRewriteService()
    private let toastPresenter = ToastPresenter()
    private let clipboardHistoryStore = ClipboardHistoryStore.shared
    private var globalHotKey: GlobalHotKey?
    private var settingsWindowController: SettingsWindowController?
    private var statusItem: NSStatusItem!
    private let statusIconView = NSImageView()
    private let spinnerView = StatusSpinnerView()
    private let maximumTranscriptionUploadBytes: UInt64 = 24 * 1024 * 1024
    private var recordedAudioURL: URL?
    private var isPreparingRecording = false
    private var isRecording = false
    private var isProcessing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        removeStaleTemporaryRecordings()
        configureNotifications()
        configureStatusItem()
        configureGlobalHotKey()
    }

    private func configureNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 26)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusButtonClicked(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        configureStatusViews()
        updateStatusIcon()
    }

    private func configureStatusViews() {
        guard let button = statusItem.button else { return }

        statusIconView.frame = NSRect(x: 3.5, y: 1.5, width: 19, height: 19)
        statusIconView.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        statusIconView.imageAlignment = .alignCenter
        statusIconView.imageScaling = .scaleProportionallyUpOrDown

        spinnerView.frame = NSRect(x: 4, y: 2, width: 18, height: 18)
        spinnerView.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        spinnerView.isHidden = true

        button.image = nil
        button.addSubview(statusIconView)
        button.addSubview(spinnerView)
    }

    @objc private func statusButtonClicked(_ sender: Any?) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
            return
        }

        toggleRecording()
    }

    private func showMenu() {
        let menu = NSMenu()

        let actionTitle = isRecording ? "Stop Recording" : "Start Recording"
        let actionItem = NSMenuItem(title: actionTitle, action: #selector(toggleRecordingFromMenu), keyEquivalent: "")
        actionItem.target = self
        actionItem.isEnabled = !isPreparingRecording && !isProcessing
        menu.addItem(actionItem)

        menu.addItem(.separator())

        let historyMenuItem = NSMenuItem(title: "Clipboard History", action: nil, keyEquivalent: "")
        historyMenuItem.submenu = clipboardHistoryMenu()
        menu.addItem(historyMenuItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func clipboardHistoryMenu() -> NSMenu {
        let menu = NSMenu()
        let items = clipboardHistoryStore.items()

        guard !items.isEmpty else {
            let emptyItem = NSMenuItem(title: "No copied replies yet", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
            return menu
        }

        for item in items {
            let menuItem = NSMenuItem(
                title: historyTitle(for: item),
                action: #selector(copyHistoryItem(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = item.text
            menu.addItem(menuItem)
        }

        menu.addItem(.separator())

        let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearClipboardHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        return menu
    }

    private func historyTitle(for item: ClipboardHistoryItem) -> String {
        let textPreview = item.text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let previewLimit = 54
        let preview: String
        if textPreview.count > previewLimit {
            let endIndex = textPreview.index(textPreview.startIndex, offsetBy: previewLimit)
            preview = String(textPreview[..<endIndex]) + "..."
        } else {
            preview = textPreview
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(preview)    \(formatter.string(from: item.createdAt))"
    }

    @objc private func copyHistoryItem(_ sender: NSMenuItem) {
        guard let text = sender.representedObject as? String else { return }

        do {
            try copyToClipboard(text)
            showNotification(title: "Geçmişten kopyalandı", body: notificationPreview(for: text))
        } catch VoiceReplyError.clipboardWriteFailed(let text) {
            showNotification(title: "Clipboard'a kopyalanamadı", body: notificationPreview(for: text))
        } catch {
            showError(error)
        }
    }

    @objc private func clearClipboardHistory() {
        clipboardHistoryStore.clear()
        showNotification(title: "Clipboard history cleared", body: "")
    }

    @objc private func toggleRecordingFromMenu() {
        toggleRecording()
    }

    private func configureGlobalHotKey() {
        do {
            let hotKey = GlobalHotKey { [weak self] in
                self?.toggleRecording()
            }
            try hotKey.register()
            globalHotKey = hotKey
        } catch {
            showError(error)
        }
    }

    private func toggleRecording() {
        guard !isPreparingRecording, !isProcessing else { return }
        isRecording ? stopRecording() : startRecording()
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
    }

    private func startRecording() {
        guard !isPreparingRecording, !isRecording, !isProcessing else { return }
        isPreparingRecording = true
        updateStatusIcon()

        Task { @MainActor in
            do {
                guard hasRequiredAPIKeys() else {
                    openSettings()
                    showNotification(title: "API key eksik", body: "DeepSeek ve transcription API keylerini Settings ekranına ekle.")
                    isPreparingRecording = false
                    updateStatusIcon()
                    return
                }

                guard try await recorder.ensureMicrophonePermission() else {
                    showNotification(title: "Microphone access needed", body: "Enable microphone access in System Settings.")
                    isPreparingRecording = false
                    updateStatusIcon()
                    return
                }

                recordedAudioURL = try recorder.start()
                isPreparingRecording = false
                isRecording = true
                updateStatusIcon()
            } catch {
                isPreparingRecording = false
                showError(error)
                updateStatusIcon()
            }
        }
    }

    private func hasRequiredAPIKeys() -> Bool {
        let deepSeekKey = KeychainStore.shared.read(account: KeychainAccount.deepSeekAPIKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let transcriptionKey = KeychainStore.shared.read(account: KeychainAccount.openAIAPIKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return !deepSeekKey.isEmpty && !transcriptionKey.isEmpty
    }

    private func stopRecording() {
        guard isRecording else { return }

        do {
            let recordedAudio = try recorder.stop()
            recordedAudioURL = recordedAudio.url
            isRecording = false
            updateStatusIcon()

            guard recordedAudio.containsSpeech else {
                try? FileManager.default.removeItem(at: recordedAudio.url)
                showNotification(title: "Ses algılanmadı", body: "Panoya bir şey kopyalanmadı.")
                return
            }

            guard recordedAudio.fileSize <= maximumTranscriptionUploadBytes else {
                try? FileManager.default.removeItem(at: recordedAudio.url)
                showError(VoiceReplyError.audioFileTooLarge)
                return
            }

            isProcessing = true
            updateStatusIcon()
            processRecording(at: recordedAudio.url)
        } catch {
            isRecording = false
            isProcessing = false
            updateStatusIcon()
            showError(error)
        }
    }

    private func processRecording(at audioURL: URL) {
        Task { @MainActor in
            defer {
                try? FileManager.default.removeItem(at: audioURL)
                isProcessing = false
                updateStatusIcon()
            }

            do {
                let settings = AppSettings.load()

                guard let deepSeekKey = KeychainStore.shared.read(account: KeychainAccount.deepSeekAPIKey), !deepSeekKey.isEmpty else {
                    openSettings()
                    throw VoiceReplyError.missingAPIKey("DeepSeek API key")
                }

                guard let transcriptionKey = KeychainStore.shared.read(account: KeychainAccount.openAIAPIKey), !transcriptionKey.isEmpty else {
                    openSettings()
                    throw VoiceReplyError.missingAPIKey("OpenAI transcription API key")
                }

                let turkishTranscript = try await transcriptionService.transcribeTurkishAudio(
                    fileURL: audioURL,
                    apiKey: transcriptionKey
                )

                guard !isLikelyEmptyTranscript(turkishTranscript) else {
                    throw VoiceReplyError.noSpeechDetected
                }

                let englishReply = try await rewriteService.rewrite(
                    turkishText: turkishTranscript,
                    tone: settings.tone,
                    outputVariant: settings.outputVariant,
                    contextPrompt: settings.contextPrompt,
                    apiKey: deepSeekKey
                )

                try copyToClipboard(englishReply)
                clipboardHistoryStore.add(englishReply)
                showNotification(
                    title: "Metin panoya kopyalandı",
                    body: notificationPreview(for: englishReply)
                )
            } catch VoiceReplyError.noSpeechDetected {
                showNotification(title: "Ses algılanmadı", body: "Panoya bir şey kopyalanmadı.")
            } catch VoiceReplyError.clipboardWriteFailed(let text) {
                showNotification(title: "Clipboard'a kopyalanamadı", body: notificationPreview(for: text))
            } catch {
                showError(error)
            }
        }
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }

        let symbolName: String
        let description: String

        if isRecording {
            symbolName = "stop.circle.fill"
            description = "Stop recording"
        } else if isPreparingRecording || isProcessing {
            symbolName = ""
            description = isPreparingRecording ? "Preparing recording" : "Processing recording"
        } else {
            symbolName = "mic.circle.fill"
            description = "Start recording"
        }

        button.toolTip = description

        if isPreparingRecording || isProcessing {
            statusIconView.image = nil
            startProcessingSpinner()
        } else {
            stopProcessingSpinner()
            statusIconView.image = statusImage(symbolName: symbolName, description: description)
        }
    }

    private func statusImage(symbolName: String, description: String) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: 19, weight: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = true
        return image
    }

    private func startProcessingSpinner() {
        statusIconView.isHidden = true
        spinnerView.startSpinning()
    }

    private func stopProcessingSpinner() {
        spinnerView.stopSpinning()
        statusIconView.isHidden = false
    }

    private func showError(_ error: Error) {
        showNotification(title: "Voice reply failed", body: error.localizedDescription)
    }

    private func notificationPreview(for text: String) -> String {
        let singleLineText = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if singleLineText.count <= 180 {
            return singleLineText
        }

        let endIndex = singleLineText.index(singleLineText.startIndex, offsetBy: 180)
        return String(singleLineText[..<endIndex]) + "..."
    }

    private func isLikelyEmptyTranscript(_ text: String) -> Bool {
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

    private func copyToClipboard(_ text: String) throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw VoiceReplyError.emptyModelResponse
        }

        let pasteboard = NSPasteboard.general
        let previousString = pasteboard.string(forType: .string)

        pasteboard.clearContents()

        guard pasteboard.setString(trimmedText, forType: .string),
              pasteboard.string(forType: .string) == trimmedText else {
            pasteboard.clearContents()
            if let previousString {
                pasteboard.setString(previousString, forType: .string)
            }
            throw VoiceReplyError.clipboardWriteFailed(trimmedText)
        }
    }

    private func removeStaleTemporaryRecordings() {
        let temporaryDirectory = FileManager.default.temporaryDirectory

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for file in files where file.lastPathComponent.hasPrefix("voice-reply-") && file.pathExtension == "m4a" {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func showNotification(title: String, body: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self?.showSystemNotification(title: title, body: body)
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    if granted {
                        self?.showSystemNotification(title: title, body: body)
                    } else {
                        DispatchQueue.main.async {
                            self?.toastPresenter.show(title: title, body: body)
                        }
                    }
                }
            case .denied:
                DispatchQueue.main.async {
                    self?.toastPresenter.show(title: title, body: body)
                }
            @unknown default:
                DispatchQueue.main.async {
                    self?.toastPresenter.show(title: title, body: body)
                }
            }
        }
    }

    private func showSystemNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            guard error != nil else { return }
            DispatchQueue.main.async {
                self?.toastPresenter.show(title: title, body: body)
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
