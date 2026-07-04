import Foundation

public enum ReplyTone: String, CaseIterable, Identifiable {
    case casual
    case neutral
    case polished

    public var id: String { rawValue }

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum OutputVariant: String, CaseIterable, Identifiable {
    case britishEnglish = "British English"
    case americanEnglish = "American English"

    public var id: String { rawValue }

    public var instruction: String {
        switch self {
        case .britishEnglish:
            return "British English spelling and everyday British phrasing"
        case .americanEnglish:
            return "American English spelling and everyday US phrasing"
        }
    }
}

public enum SpeechLanguage: String, CaseIterable, Identifiable {
    case turkish = "Turkish"

    public var id: String { rawValue }

    public var apiLanguageCode: String {
        switch self {
        case .turkish:
            return "tr"
        }
    }

    public var transcriptionPrompt: String {
        switch self {
        case .turkish:
            return "Turkish workplace voice reply. It may include English product names and technical terms such as Slack, Framer, GitHub, Codex, OpenAI, DeepSeek, API, design, developer, release, and bug."
        }
    }
}

public enum ShortcutOption: String, CaseIterable, Identifiable {
    case controlOptionCommandSpace
    case controlOptionCommandR
    case controlOptionCommandReturn
    case controlOptionCommandM

    public var id: String { rawValue }

    public var displayName: String {
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

public struct AppSettings {
    public var tone: ReplyTone
    public var outputVariant: OutputVariant
    public var speechLanguage: SpeechLanguage
    public var contextPrompt: String
    public var shortcut: ShortcutOption
    public var saveClipboardHistory: Bool
    public var startRecordingOnLaunch: Bool

    public init(
        tone: ReplyTone = .casual,
        outputVariant: OutputVariant = .britishEnglish,
        speechLanguage: SpeechLanguage = .turkish,
        contextPrompt: String = "",
        shortcut: ShortcutOption = .controlOptionCommandSpace,
        saveClipboardHistory: Bool = true,
        startRecordingOnLaunch: Bool = false
    ) {
        self.tone = tone
        self.outputVariant = outputVariant
        self.speechLanguage = speechLanguage
        self.contextPrompt = contextPrompt
        self.shortcut = shortcut
        self.saveClipboardHistory = saveClipboardHistory
        self.startRecordingOnLaunch = startRecordingOnLaunch
    }

    private enum Keys {
        static let tone = "tone"
        static let outputVariant = "outputVariant"
        static let speechLanguage = "speechLanguage"
        static let contextPrompt = "contextPrompt"
        static let shortcut = "shortcut"
        static let saveClipboardHistory = "saveClipboardHistory"
        static let startRecordingOnLaunch = "startRecordingOnLaunch"
    }

    public static func load(defaults: UserDefaults = .standard) -> AppSettings {
        let toneValue = defaults.string(forKey: Keys.tone)
        let variantValue = defaults.string(forKey: Keys.outputVariant)
        let speechLanguageValue = defaults.string(forKey: Keys.speechLanguage)
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
            speechLanguage: speechLanguageValue.flatMap(SpeechLanguage.init(rawValue:)) ?? .turkish,
            contextPrompt: contextPrompt,
            shortcut: shortcutValue.flatMap(ShortcutOption.init(rawValue:)) ?? .controlOptionCommandSpace,
            saveClipboardHistory: saveClipboardHistory,
            startRecordingOnLaunch: defaults.bool(forKey: Keys.startRecordingOnLaunch)
        )
    }

    public func save(defaults: UserDefaults = .standard) {
        defaults.set(tone.rawValue, forKey: Keys.tone)
        defaults.set(outputVariant.rawValue, forKey: Keys.outputVariant)
        defaults.set(speechLanguage.rawValue, forKey: Keys.speechLanguage)
        defaults.set(contextPrompt, forKey: Keys.contextPrompt)
        defaults.set(shortcut.rawValue, forKey: Keys.shortcut)
        defaults.set(saveClipboardHistory, forKey: Keys.saveClipboardHistory)
        defaults.set(startRecordingOnLaunch, forKey: Keys.startRecordingOnLaunch)
    }
}

public extension Notification.Name {
    static let voiceReplySettingsDidChange = Notification.Name("voiceReplySettingsDidChange")
}
