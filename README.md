# FinMate

Kişisel gelir, gider, yatırım ve fiş takibi yapan, SwiftUI ile yazılmış bir iOS uygulaması. Bitirme tezi kapsamında geliştirilmiştir.

## Özellikler

- **Gelir / gider takibi** — kategori bazlı kayıt, günlük / aylık / yıllık raporlar.
- **Ödeme takvimi** — düzenli (haftalık / aylık / yıllık) ödemeler için yerel bildirimle hatırlatma.
- **Yatırım modülü** — döviz, değerli metal ve kripto varlıklar için canlı fiyat çekimi (CollectAPI), TRY bazlı portföy görünümü ve donut grafik.
- **Fiş tarayıcı** — VisionKit ile fiş fotoğrafı alma, Google Gemini Vision API ile kalem kalem otomatik ayrıştırma.
- **Güvenlik** — onboarding'de seçilebilen 4 haneli PIN veya Face ID / Touch ID, SHA-256 + salt ile saklanan şifre, son 3 şifrenin yeniden kullanımının engellenmesi.
- **Çoklu para birimi** — TRY varsayılan, anlık kurla USD / EUR / GBP gösterimi.
- **Karanlık tema** — neon vurgulu, glass card tabanlı tutarlı bir tasarım sistemi.

## Kullanılan teknolojiler

- Swift 5 · SwiftUI · iOS 18.5+
- Core Data (işlem ve ödeme takvimi kalıcılığı)
- SwiftData (yatırım holdings)
- VisionKit (`VNDocumentCameraViewController`)
- UserNotifications (yerel hatırlatmalar)
- LocalAuthentication (Face ID / Touch ID)
- Charts (yerleşik Swift Charts framework'ü)

## Klasör yapısı

```
FinMate/
├── FinMate.xcodeproj/
└── FinMate/
    ├── App/                 # Uygulama giriş noktası ve kök view
    ├── CoreData/            # Core Data modeli ve PersistenceController
    ├── Models/              # Veri modelleri (Transaction, AssetSymbol, Holding, Quote)
    ├── ViewModels/          # ObservableObject / @Observable ViewModels
    ├── Services/            # API sağlayıcılar, bildirim, depolama, şifre yöneticisi
    ├── Config/              # API key giriş noktaları (Secrets.swift gitignore'da)
    ├── Resources/           # Assets.xcassets, DesignSystem
    └── Views/
        ├── Main/            # Anasayfa ve grafikler
        ├── Transactions/    # Gelir / gider ekleme ve listeleme
        ├── Categories/      # Kategori yönetimi
        ├── Reports/         # Raporlar
        ├── PaymentSchedule/ # Ödeme takvimi
        ├── Investments/     # Yatırımlar
        ├── Receipts/        # Fiş tarama ve listesi
        ├── Settings/        # Ayarlar
        └── Onboarding/      # İlk açılış, splash, kilit ekranı
```

## Kurulum

1. Repoyu klonlayın:
   ```bash
   git clone <repo-url>
   cd FinMate
   ```

2. API anahtarlarını ayarlayın:
   ```bash
   cp FinMate/Config/Secrets.swift.template FinMate/Config/Secrets.swift
   ```
   Ardından `Secrets.swift` içine kendi anahtarlarınızı girin:
   - `collectAPIKey` → [CollectAPI](https://collectapi.com/) (canlı kur / metal / kripto fiyatları)
   - `geminiAPIKey` → [Google AI Studio](https://ai.google.dev/) (fiş okuma)

   > `Secrets.swift` `.gitignore` ile takipten çıkarılmıştır, gerçek anahtarlar repoya gönderilmez.

3. `FinMate.xcodeproj` dosyasını Xcode 16+ ile açın ve çalıştırın. Hedef cihaz: iOS 18.5+.

## Geliştirici

Berke Boran — Bitirme Ödevi, 2025–2026.
