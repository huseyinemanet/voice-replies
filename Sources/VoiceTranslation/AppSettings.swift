import Foundation

enum ReplyTone: String, CaseIterable {
    case casual
    case neutral
    case polished

    var displayName: String {
        rawValue.capitalized
    }
}

enum OutputVariant: String, CaseIterable {
    case britishEnglish = "British English"
    case americanEnglish = "American English"

    var instruction: String {
        switch self {
        case .britishEnglish:
            return "British English spelling and everyday British phrasing"
        case .americanEnglish:
            return "American English spelling and everyday US phrasing"
        }
    }
}

enum ShortcutOption: String, CaseIterable {
    case controlOptionCommandSpace
    case controlOptionCommandR
    case controlOptionCommandReturn
    case controlOptionCommandM

    var displayName: String {
        switch self {
        case .controlOptionCommandSpace:
            return "Control + Option + Command + Space"
        case .controlOptionCommandR:
            return "Control + Option + Command + R"
        case .controlOptionCommandReturn:
            return "Control + Option + Command + Return"
        case .controlOptionCommandM:
            return "Control + Option + Command + M"
        }
    }
}

struct AppSettings {
    var tone: ReplyTone
    var outputVariant: OutputVariant
    var contextPrompt: String
    var shortcut: ShortcutOption
    var saveClipboardHistory: Bool

    private enum Keys {
        static let tone = "tone"
        static let outputVariant = "outputVariant"
        static let contextPrompt = "contextPrompt"
        static let shortcut = "shortcut"
        static let saveClipboardHistory = "saveClipboardHistory"
    }

    static func load(defaults: UserDefaults = .standard) -> AppSettings {
        let toneValue = defaults.string(forKey: Keys.tone)
        let variantValue = defaults.string(forKey: Keys.outputVariant)
        let contextPrompt = defaults.string(forKey: Keys.contextPrompt) ?? ""
        let shortcutValue = defaults.string(forKey: Keys.shortcut)
        let saveClipboardHistory: Bool

        if defaults.object(forKey: Keys.saveClipboardHistory) == nil {
            saveClipboardHistory = true
        } else {
            saveClipboardHistory = defaults.bool(forKey: Keys.saveClipboardHistory)
        }

        return AppSettings(
            tone: toneValue.flatMap(ReplyTone.init(rawValue:)) ?? .casual,
            outputVariant: variantValue.flatMap(OutputVariant.init(rawValue:)) ?? .britishEnglish,
            contextPrompt: contextPrompt,
            shortcut: shortcutValue.flatMap(ShortcutOption.init(rawValue:)) ?? .controlOptionCommandSpace,
            saveClipboardHistory: saveClipboardHistory
        )
    }

    func save(defaults: UserDefaults = .standard) {
        defaults.set(tone.rawValue, forKey: Keys.tone)
        defaults.set(outputVariant.rawValue, forKey: Keys.outputVariant)
        defaults.set(contextPrompt, forKey: Keys.contextPrompt)
        defaults.set(shortcut.rawValue, forKey: Keys.shortcut)
        defaults.set(saveClipboardHistory, forKey: Keys.saveClipboardHistory)
    }
}

extension Notification.Name {
    static let voiceReplySettingsDidChange = Notification.Name("voiceReplySettingsDidChange")
}
