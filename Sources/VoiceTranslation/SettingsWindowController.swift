import AppKit

final class SettingsWindowController: NSWindowController {
    private let deepSeekField = NSSecureTextField()
    private let openAIField = NSSecureTextField()
    private let tonePopUp = NSPopUpButton()
    private let variantPopUp = NSPopUpButton()

    private enum Layout {
        static let windowWidth: CGFloat = 620
        static let windowHeight: CGFloat = 410
        static let contentPadding: CGFloat = 32
        static let labelWidth: CGFloat = 220
        static let controlWidth: CGFloat = 300
        static let controlHeight: CGFloat = 32
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
                    subtitle: "Rewrites the Turkish transcript into natural British English.",
                    control: deepSeekField
                ),
                formRow(
                    title: "Transcription API Key",
                    subtitle: "OpenAI key used for Turkish speech-to-text.",
                    control: openAIField
                )
            ]
        ))
        content.addArrangedSubview(formSection(
            title: "Reply Style",
            rows: [
                formRow(
                    title: "Tone",
                    subtitle: "Controls how relaxed or polished the final Slack reply feels.",
                    control: tonePopUp
                ),
                formRow(
                    title: "Output Variant",
                    subtitle: "The app currently writes in British English.",
                    control: variantPopUp
                ),
                formRow(
                    title: "Keyboard Shortcut",
                    subtitle: "Press once to record, then again to stop and translate.",
                    control: shortcutBadge()
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
        openAIField.placeholderString = "OPENAI_API_KEY"

        [deepSeekField, openAIField].forEach { field in
            field.bezelStyle = .roundedBezel
            field.controlSize = .large
            field.font = .systemFont(ofSize: 13)
            field.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                field.widthAnchor.constraint(equalToConstant: Layout.controlWidth),
                field.heightAnchor.constraint(equalToConstant: Layout.controlHeight)
            ])
        }

        tonePopUp.addItems(withTitles: ReplyTone.allCases.map(\.displayName))
        variantPopUp.addItems(withTitles: OutputVariant.allCases.map(\.rawValue))

        [tonePopUp, variantPopUp].forEach { popUp in
            popUp.controlSize = .large
            popUp.bezelStyle = .rounded
            popUp.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                popUp.widthAnchor.constraint(equalToConstant: Layout.controlWidth),
                popUp.heightAnchor.constraint(equalToConstant: Layout.controlHeight)
            ])
        }
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

        let subtitle = NSTextField(wrappingLabelWithString: "Keep your provider keys local, choose the reply style, and use the shortcut from anywhere on your Mac.")
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

    private func shortcutBadge() -> NSView {
        let label = NSTextField(labelWithString: GlobalHotKey.displayName)
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.cornerRadius = 8
        label.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: Layout.controlWidth),
            label.heightAnchor.constraint(equalToConstant: Layout.controlHeight)
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

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.controlSize = .large
        saveButton.keyEquivalent = "\r"

        row.addArrangedSubview(spacer)
        row.addArrangedSubview(saveButton)
        return row
    }

    private func loadValues() {
        let settings = AppSettings.load()

        deepSeekField.stringValue = KeychainStore.shared.read(account: KeychainAccount.deepSeekAPIKey) ?? ""
        openAIField.stringValue = KeychainStore.shared.read(account: KeychainAccount.openAIAPIKey) ?? ""
        tonePopUp.selectItem(withTitle: settings.tone.displayName)
        variantPopUp.selectItem(withTitle: settings.outputVariant.rawValue)
    }

    @objc private func save() {
        do {
            try KeychainStore.shared.save(deepSeekField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines), account: KeychainAccount.deepSeekAPIKey)
            try KeychainStore.shared.save(openAIField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines), account: KeychainAccount.openAIAPIKey)

            let toneTitle = tonePopUp.selectedItem?.title ?? ReplyTone.casual.displayName
            let variantTitle = variantPopUp.selectedItem?.title ?? OutputVariant.britishEnglish.rawValue

            let settings = AppSettings(
                tone: ReplyTone.allCases.first(where: { $0.displayName == toneTitle }) ?? .casual,
                outputVariant: OutputVariant(rawValue: variantTitle) ?? .britishEnglish
            )
            settings.save()

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
