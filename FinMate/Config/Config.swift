import Foundation

/// Uygulamanın 3. parti servislere erişim anahtarlarına dair giriş noktası.
///
/// Gerçek anahtarlar bu dosyada DEĞİL, `Secrets.swift` içinde tutulur.
/// `Secrets.swift` `.gitignore` ile takipten çıkarılmıştır ve git'e gönderilmez.
/// Projeyi ilk defa klonlayan biri için `Secrets.swift.template` dosyasını
/// `Secrets.swift` olarak kopyalayıp kendi anahtarlarını girmesi yeterlidir.
enum Config {
    static var collectAPIKey: String { Secrets.collectAPIKey }
    static var geminiAPIKey: String { Secrets.geminiAPIKey }

    static var hasValidAPIKey: Bool {
        !collectAPIKey.isEmpty && collectAPIKey != "REPLACE_WITH_YOUR_COLLECTAPI_KEY"
    }

    static var hasValidGeminiKey: Bool {
        !geminiAPIKey.isEmpty && geminiAPIKey != "REPLACE_WITH_YOUR_GEMINI_API_KEY"
    }
}
