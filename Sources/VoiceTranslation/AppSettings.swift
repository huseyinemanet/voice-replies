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

struct AppSettings {
    var tone: ReplyTone
    var outputVariant: OutputVariant

    private enum Keys {
        static let tone = "tone"
        static let outputVariant = "outputVariant"
    }

    static func load(defaults: UserDefaults = .standard) -> AppSettings {
        let toneValue = defaults.string(forKey: Keys.tone)
        let variantValue = defaults.string(forKey: Keys.outputVariant)

        return AppSettings(
            tone: toneValue.flatMap(ReplyTone.init(rawValue:)) ?? .casual,
            outputVariant: variantValue.flatMap(OutputVariant.init(rawValue:)) ?? .britishEnglish
        )
    }

    func save(defaults: UserDefaults = .standard) {
        defaults.set(tone.rawValue, forKey: Keys.tone)
        defaults.set(outputVariant.rawValue, forKey: Keys.outputVariant)
    }
}
