import AppKit

final class SettingsWindowController: NSWindowController {
    private let deepSeekField = NSSecureTextField()
    private let openAIField = NSSecureTextField()
    private let tonePopUp = NSPopUpButton()
    private let variantPopUp = NSPopUpButton()
    private let statusLabel = NSTextField(labelWithString: "")

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 290),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Voice Reply Settings"
        window.center()
        self.init(window: window)
        buildUI()
        loadValues()
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 22, left: 22, bottom: 22, right: 22)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        deepSeekField.placeholderString = "DEEPSEEK_API_KEY"
        openAIField.placeholderString = "OPENAI_API_KEY"

        tonePopUp.addItems(withTitles: ReplyTone.allCases.map(\.displayName))
        variantPopUp.addItems(withTitles: OutputVariant.allCases.map(\.rawValue))

        stack.addArrangedSubview(row(label: "DeepSeek API key", control: deepSeekField))
        stack.addArrangedSubview(row(label: "Transcription API key", control: openAIField))
        stack.addArrangedSubview(row(label: "Tone", control: tonePopUp))
        stack.addArrangedSubview(row(label: "Output variant", control: variantPopUp))
        stack.addArrangedSubview(row(label: "Keyboard shortcut", control: NSTextField(labelWithString: GlobalHotKey.displayName)))

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 10

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        buttonRow.addArrangedSubview(saveButton)
        buttonRow.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(buttonRow)
    }

    private func row(label: String, control: NSView) -> NSStackView {
        let labelView = NSTextField(labelWithString: label)
        labelView.widthAnchor.constraint(equalToConstant: 150).isActive = true

        control.translatesAutoresizingMaskIntoConstraints = false
        control.widthAnchor.constraint(greaterThanOrEqualToConstant: 250).isActive = true

        let row = NSStackView(views: [labelView, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
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

            statusLabel.stringValue = "Saved"
        } catch {
            statusLabel.stringValue = error.localizedDescription
        }
    }
}
