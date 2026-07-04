import AppKit
#if canImport(VoiceRepliesCore)
import VoiceRepliesCore
#endif

final class SettingsWindowController: NSWindowController {
    private let deepSeekField = NSSecureTextField()
    private let tonePopUp = NSPopUpButton()
    private let variantPopUp = NSPopUpButton()
    private let shortcutPopUp = NSPopUpButton()
    private let saveHistoryCheckbox = NSButton(checkboxWithTitle: "Save history", target: nil, action: nil)
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Open at login", target: nil, action: nil)
    private let contextPromptTextView = NSTextView()

    private enum Layout {
        static let windowWidth: CGFloat = 620
        static let windowHeight: CGFloat = 580
        static let contentPadding: CGFloat = 32
        static let labelWidth: CGFloat = 220
        static let controlWidth: CGFloat = 300
        static let controlHeight: CGFloat = 30
        static let contextHeight: CGFloat = 72
        static let rowGap: CGFloat = 14
        static let sectionGap: CGFloat = 24
    }

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Layout.windowWidth, height: Layout.windowHeight),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()

        self.init(window: window)
        buildUI()
        loadValues()
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        let root = NSVisualEffectView()
        root.material = .windowBackground
        root.blendingMode = .behindWindow
        root.state = .active
        root.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        let content = NSStackView()
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = Layout.sectionGap
        content.edgeInsets = NSEdgeInsets(
            top: Layout.contentPadding,
            left: Layout.contentPadding,
            bottom: 24,
            right: Layout.contentPadding
        )
        content.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(content)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            content.topAnchor.constraint(equalTo: root.topAnchor),
            content.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        configureControls()

        content.addArrangedSubview(header())
        content.addArrangedSubview(formSection(
            title: "Providers",
            rows: [
                formRow(
                    title: "DeepSeek API Key",
                    subtitle: "Turns transcripts into English.",
                    control: deepSeekField
                ),
                formRow(
                    title: "Transcription",
                    subtitle: "Used for speech-to-text.",
                    control: freeTranscriptionLabel()
                )
            ]
        ))
        content.addArrangedSubview(formSection(
            title: "Reply Style",
            rows: [
                formRow(
                    title: "Tone",
                    subtitle: "How the reply should feel.",
                    control: tonePopUp
                ),
                formRow(
                    title: "Output Variant",
                    subtitle: "British or American English.",
                    control: variantPopUp
                ),
                formRow(
                    title: "Context Prompt",
                    subtitle: "Optional extra guidance.",
                    control: contextPromptControl()
                ),
                formRow(
                    title: "Keyboard Shortcut",
                    subtitle: "Start and stop recording.",
                    control: shortcutPopUp
                )
            ]
        ))
        content.addArrangedSubview(formSection(
            title: "Privacy & Automation",
            rows: [
                formRow(
                    title: "Clipboard History",
                    subtitle: "Keep recent replies.",
                    control: saveHistoryCheckbox
                ),
                formRow(
                    title: "Launch at Login",
                    subtitle: "Start after restart.",
                    control: launchAtLoginCheckbox
                )
            ]
        ))

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        content.addArrangedSubview(spacer)
        content.addArrangedSubview(footer())
    }

    private func configureControls() {
        deepSeekField.placeholderString = "DEEPSEEK_API_KEY"

        [deepSeekField].forEach { field in
            field.bezelStyle = .roundedBezel
            field.controlSize = .large
            field.font = .systemFont(ofSize: 13)
            field.lineBreakMode = .byClipping
            field.cell?.wraps = false
            field.cell?.isScrollable = true
            field.cell?.usesSingleLineMode = true
            field.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                field.widthAnchor.constraint(equalToConstant: Layout.controlWidth),
                field.heightAnchor.constraint(equalToConstant: Layout.controlHeight)
            ])
        }

        tonePopUp.addItems(withTitles: ReplyTone.allCases.map(\.displayName))
        variantPopUp.addItems(withTitles: OutputVariant.allCases.map(\.rawValue))
        shortcutPopUp.addItems(withTitles: ShortcutOption.allCases.map(\.displayName))

        [tonePopUp, variantPopUp, shortcutPopUp].forEach { popUp in
            popUp.controlSize = .large
            popUp.bezelStyle = .rounded
            popUp.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                popUp.widthAnchor.constraint(equalToConstant: Layout.controlWidth),
                popUp.heightAnchor.constraint(equalToConstant: Layout.controlHeight)
            ])
        }

        [saveHistoryCheckbox, launchAtLoginCheckbox].forEach { checkbox in
            checkbox.font = .systemFont(ofSize: 13)
            checkbox.controlSize = .regular
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                checkbox.widthAnchor.constraint(equalToConstant: Layout.controlWidth),
                checkbox.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.controlHeight)
            ])
        }

        contextPromptTextView.font = .systemFont(ofSize: 13)
        contextPromptTextView.textColor = .labelColor
        contextPromptTextView.backgroundColor = .textBackgroundColor
        contextPromptTextView.isRichText = false
        contextPromptTextView.isAutomaticQuoteSubstitutionEnabled = false
        contextPromptTextView.isAutomaticDashSubstitutionEnabled = false
        contextPromptTextView.isAutomaticSpellingCorrectionEnabled = false
        contextPromptTextView.textContainerInset = NSSize(width: 10, height: 7)
        contextPromptTextView.textContainer?.widthTracksTextView = true
        contextPromptTextView.textContainer?.heightTracksTextView = false
    }

    private func header() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(equalToConstant: Layout.windowWidth - (Layout.contentPadding * 2)).isActive = true

        let title = NSTextField(labelWithString: "Voice Replies")
        title.font = .systemFont(ofSize: 24, weight: .semibold)
        title.textColor = .labelColor
        title.alignment = .left

        let subtitle = NSTextField(wrappingLabelWithString: "Set your keys, reply style, and shortcut.")
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .left
        subtitle.maximumNumberOfLines = 2

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        return stack
    }

    private func formSection(title: String, rows: [NSView]) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = Layout.rowGap
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.widthAnchor.constraint(equalToConstant: Layout.windowWidth - (Layout.contentPadding * 2)).isActive = true

        let sectionTitle = NSTextField(labelWithString: title)
        sectionTitle.font = .systemFont(ofSize: 12, weight: .semibold)
        sectionTitle.textColor = .secondaryLabelColor
        sectionTitle.alignment = .left
        stack.addArrangedSubview(sectionTitle)

        rows.forEach { stack.addArrangedSubview($0) }
        return stack
    }

    private func formRow(title: String, subtitle: String, control: NSView) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 24
        row.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalToConstant: Layout.windowWidth - (Layout.contentPadding * 2)).isActive = true

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.widthAnchor.constraint(equalToConstant: Layout.labelWidth).isActive = true

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .left

        let subtitleLabel = NSTextField(wrappingLabelWithString: subtitle)
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.alignment = .left
        subtitleLabel.maximumNumberOfLines = 2

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        control.setContentHuggingPriority(.required, for: .horizontal)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(control)
        return row
    }

    private func contextPromptControl() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 8
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.55).cgColor
        container.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = contextPromptTextView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Layout.controlWidth),
            container.heightAnchor.constraint(equalToConstant: Layout.contextHeight),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 1),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -1),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor, constant: 1),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -1)
        ])

        return container
    }

    private func freeTranscriptionLabel() -> NSView {
        let label = NSTextField(labelWithString: "Apple Speech, free")
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: Layout.controlWidth),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.controlHeight)
        ])

        return label
    }

    private func footer() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalToConstant: Layout.windowWidth - (Layout.contentPadding * 2)).isActive = true

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let creditLabel = NSTextField(labelWithString: "Designed and developed by Huseyin Emanet")
        creditLabel.font = .systemFont(ofSize: 11)
        creditLabel.textColor = .tertiaryLabelColor
        creditLabel.alignment = .left

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.controlSize = .large
        saveButton.keyEquivalent = "\r"

        row.addArrangedSubview(creditLabel)
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(saveButton)
        return row
    }

    private func loadValues() {
        let settings = AppSettings.load()

        deepSeekField.stringValue = KeychainStore.shared.read(account: KeychainAccount.deepSeekAPIKey) ?? ""
        tonePopUp.selectItem(withTitle: settings.tone.displayName)
        variantPopUp.selectItem(withTitle: settings.outputVariant.rawValue)
        shortcutPopUp.selectItem(withTitle: settings.shortcut.displayName)
        saveHistoryCheckbox.state = settings.saveClipboardHistory ? .on : .off
        launchAtLoginCheckbox.state = LaunchAtLoginController.isEnabled ? .on : .off
        contextPromptTextView.string = settings.contextPrompt
    }

    @objc private func save() {
        do {
            let deepSeekKey = deepSeekField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

            if deepSeekKey.isEmpty {
                try KeychainStore.shared.delete(account: KeychainAccount.deepSeekAPIKey)
            } else {
                try KeychainStore.shared.save(deepSeekKey, account: KeychainAccount.deepSeekAPIKey)
            }

            let toneTitle = tonePopUp.selectedItem?.title ?? ReplyTone.casual.displayName
            let variantTitle = variantPopUp.selectedItem?.title ?? OutputVariant.britishEnglish.rawValue
            let shortcutTitle = shortcutPopUp.selectedItem?.title ?? ShortcutOption.controlOptionCommandSpace.displayName
            let saveHistory = saveHistoryCheckbox.state == .on
            try LaunchAtLoginController.setEnabled(launchAtLoginCheckbox.state == .on)

            let settings = AppSettings(
                tone: ReplyTone.allCases.first(where: { $0.displayName == toneTitle }) ?? .casual,
                outputVariant: OutputVariant(rawValue: variantTitle) ?? .britishEnglish,
                contextPrompt: contextPromptTextView.string.trimmingCharacters(in: .whitespacesAndNewlines),
                shortcut: ShortcutOption.allCases.first(where: { $0.displayName == shortcutTitle }) ?? .controlOptionCommandSpace,
                saveClipboardHistory: saveHistory,
                startRecordingOnLaunch: AppSettings.load().startRecordingOnLaunch
            )
            settings.save()

            if !saveHistory {
                ClipboardHistoryStore.shared.clear()
            }

            NotificationCenter.default.post(name: .voiceReplySettingsDidChange, object: nil)
            window?.close()
        } catch {
            showErrorAlert(message: error.localizedDescription)
        }
    }

    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Settings could not be saved"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window ?? NSWindow()) { _ in }
    }
}
