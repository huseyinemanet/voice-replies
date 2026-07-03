import AppKit

final class SettingsWindowController: NSWindowController {
    private let deepSeekField = NSSecureTextField()
    private let openAIField = NSSecureTextField()
    private let tonePopUp = NSPopUpButton()
    private let variantPopUp = NSPopUpButton()
    private let statusLabel = NSTextField(labelWithString: "")

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 430),
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

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 18
        stack.edgeInsets = NSEdgeInsets(top: 34, left: 28, bottom: 24, right: 28)
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        stack.addArrangedSubview(header())
        stack.addArrangedSubview(section(
            title: "Providers",
            rows: [
                settingsRow(
                    title: "DeepSeek API Key",
                    subtitle: "Used to rewrite your Turkish transcript into natural British English.",
                    control: deepSeekField
                ),
                settingsRow(
                    title: "Transcription API Key",
                    subtitle: "OpenAI key used for Turkish speech-to-text.",
                    control: openAIField
                )
            ]
        ))
        stack.addArrangedSubview(section(
            title: "Reply Style",
            rows: [
                settingsRow(
                    title: "Tone",
                    subtitle: "Controls how relaxed or polished the final Slack reply feels.",
                    control: tonePopUp
                ),
                settingsRow(
                    title: "Output Variant",
                    subtitle: "The app currently writes in British English.",
                    control: variantPopUp
                ),
                settingsRow(
                    title: "Keyboard Shortcut",
                    subtitle: "Press once to record, press again to stop and translate.",
                    control: shortcutBadge()
                )
            ]
        ))

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stack.addArrangedSubview(spacer)
        stack.addArrangedSubview(footer())

        configureControls()
    }

    private func configureControls() {
        deepSeekField.placeholderString = "DEEPSEEK_API_KEY"
        openAIField.placeholderString = "OPENAI_API_KEY"

        [deepSeekField, openAIField].forEach { field in
            field.bezelStyle = .roundedBezel
            field.controlSize = .large
            field.font = .systemFont(ofSize: 13)
            field.translatesAutoresizingMaskIntoConstraints = false
            field.widthAnchor.constraint(equalToConstant: 245).isActive = true
        }

        tonePopUp.addItems(withTitles: ReplyTone.allCases.map(\.displayName))
        variantPopUp.addItems(withTitles: OutputVariant.allCases.map(\.rawValue))

        [tonePopUp, variantPopUp].forEach { popUp in
            popUp.controlSize = .large
            popUp.bezelStyle = .rounded
            popUp.translatesAutoresizingMaskIntoConstraints = false
            popUp.widthAnchor.constraint(equalToConstant: 245).isActive = true
        }
    }

    private func header() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 5

        let title = NSTextField(labelWithString: "Voice Replies")
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        title.textColor = .labelColor

        let subtitle = NSTextField(wrappingLabelWithString: "Keep your provider keys local, choose the reply style, and use the shortcut from anywhere on your Mac.")
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor
        subtitle.maximumNumberOfLines = 2

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        return stack
    }

    private func section(title: String, rows: [NSView]) -> NSView {
        let outer = NSStackView()
        outer.orientation = .vertical
        outer.spacing = 8

        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor

        let card = NSVisualEffectView()
        card.material = .contentBackground
        card.blendingMode = .withinWindow
        card.state = .active
        card.wantsLayer = true
        card.layer?.cornerRadius = 12
        card.layer?.masksToBounds = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        for (index, row) in rows.enumerated() {
            stack.addArrangedSubview(row)
            if index < rows.count - 1 {
                stack.addArrangedSubview(separator())
            }
        }

        outer.addArrangedSubview(label)
        outer.addArrangedSubview(card)
        return outer
    }

    private func settingsRow(title: String, subtitle: String, control: NSView) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 18
        row.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.spacing = 3

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .labelColor

        let subtitleLabel = NSTextField(wrappingLabelWithString: subtitle)
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        control.setContentHuggingPriority(.required, for: .horizontal)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(control)
        return row
    }

    private func separator() -> NSView {
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    private func shortcutBadge() -> NSView {
        let label = NSTextField(labelWithString: GlobalHotKey.displayName)
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.cornerRadius = 7
        label.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: 245),
            label.heightAnchor.constraint(equalToConstant: 30)
        ])
        return label
    }

    private func footer() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.lineBreakMode = .byTruncatingTail

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.controlSize = .large
        saveButton.keyEquivalent = "\r"

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(statusLabel)
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

            statusLabel.stringValue = "Saved locally"
        } catch {
            statusLabel.stringValue = error.localizedDescription
        }
    }
}
