import Foundation
import Security

enum KeychainAccount {
    static let deepSeekAPIKey = "DEEPSEEK_API_KEY"
    static let openAIAPIKey = "OPENAI_API_KEY"
}

final class KeychainStore {
    static let shared = KeychainStore()

    private let service = "com.local.voice-translation"

    private init() {}

    func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    func save(_ value: String, account: String) throws {
        let encoded = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: encoded
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = encoded
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw VoiceReplyError.keychainFailure(addStatus)
            }
            return
        }

        guard status == errSecSuccess else {
            throw VoiceReplyError.keychainFailure(status)
        }
    }
}
