import Foundation

public struct ClipboardHistoryItem: Codable, Identifiable {
    public let id: UUID
    public let text: String
    public let createdAt: Date
}

public final class ClipboardHistoryStore {
    public static let shared = ClipboardHistoryStore()

    private let maximumItems = 20
    private let defaultsKey = "clipboardHistoryItems"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func items() -> [ClipboardHistoryItem] {
        guard let data = defaults.data(forKey: defaultsKey),
              let items = try? JSONDecoder().decode([ClipboardHistoryItem].self, from: data) else {
            return []
        }

        return items
    }

    public func add(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        var currentItems = items()
        currentItems.removeAll { $0.text == trimmedText }
        currentItems.insert(
            ClipboardHistoryItem(id: UUID(), text: trimmedText, createdAt: Date()),
            at: 0
        )
        save(Array(currentItems.prefix(maximumItems)))
    }

    public func clear() {
        defaults.removeObject(forKey: defaultsKey)
    }

    private func save(_ items: [ClipboardHistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
