
import Foundation
import CryptoKit

enum PasscodeManager {
    private static let salt = "FinMate_v1_pcode_salt_2026"
    private static let historyKey = "settings.passcodeHistory"
    private static let historyMax = 3

    static func hash(_ code: String) -> String {
        let combined = salt + code
        let digest = SHA256.hash(data: Data(combined.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func save(_ code: String?) {
        let defaults = UserDefaults.standard
        guard let code, !code.isEmpty else {
            defaults.removeObject(forKey: SettingsKeys.passcodeHash)
            defaults.removeObject(forKey: historyKey)
            return
        }

        if let current = defaults.string(forKey: SettingsKeys.passcodeHash), !current.isEmpty {
            var history = defaults.stringArray(forKey: historyKey) ?? []
            history.removeAll(where: { $0 == current }) // duplikat olmasın
            history.insert(current, at: 0)
            if history.count > historyMax {
                history = Array(history.prefix(historyMax))
            }
            defaults.set(history, forKey: historyKey)
        }

        defaults.set(hash(code), forKey: SettingsKeys.passcodeHash)
    }

    static var isSet: Bool {
        guard let v = UserDefaults.standard.string(forKey: SettingsKeys.passcodeHash) else { return false }
        return !v.isEmpty
    }

    static func verify(_ code: String) -> Bool {
        guard let stored = UserDefaults.standard.string(forKey: SettingsKeys.passcodeHash) else { return false }
        return stored == hash(code)
    }

    static func isRecentlyUsed(_ code: String) -> Bool {
        let h = hash(code)
        let defaults = UserDefaults.standard

        if let current = defaults.string(forKey: SettingsKeys.passcodeHash), current == h {
            return true
        }
        let history = defaults.stringArray(forKey: historyKey) ?? []
        return history.contains(h)
    }
}
