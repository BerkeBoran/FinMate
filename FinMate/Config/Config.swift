import Foundation

enum Config {
    static let collectAPIKey: String = "REDACTED"

    static let geminiAPIKey: String = "REDACTED"

    static var hasValidAPIKey: Bool {
        !collectAPIKey.isEmpty && collectAPIKey != "REPLACE_WITH_YOUR_COLLECTAPI_KEY"
    }

    static var hasValidGeminiKey: Bool {
        !geminiAPIKey.isEmpty && geminiAPIKey != "REPLACE_WITH_YOUR_GEMINI_API_KEY"
    }
}
