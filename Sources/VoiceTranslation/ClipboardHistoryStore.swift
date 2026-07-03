import Foundation

struct ClipboardHistoryItem: Codable, Identifiable {
    let id: UUID
    let text: String
    let createdAt: Date
}

final class ClipboardHistoryStore {
    static let shared = ClipboardHistoryStore()

    private let maximumItems = 20
    private let defaultsKey = "clipboardHistoryItems"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func items() -> [ClipboardHistoryItem] {
        guard let data = defaults.data(forKey: defaultsKey),
              let items = try? JSONDecoder().decode([ClipboardHistoryItem].self, from: data) else {
            return []
        }

        return items
    }

    func add(_ text: String) {
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

    func clear() {
        defaults.removeObject(forKey: defaultsKey)
    }

    private func save(_ items: [ClipboardHistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
