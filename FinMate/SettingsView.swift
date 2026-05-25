//
//  SettingsView.swift
//  FinMate
//
//  Created by Berke Boran on 25.05.2026.
//

import SwiftUI
import LocalAuthentication
import UserNotifications

// MARK: - Settings Keys
enum SettingsKeys {
    static let onboardingCompleted = "settings.onboardingCompleted"
    static let userName = "settings.userName"       // ad
    static let lastName = "settings.lastName"       // soyad
    static let userIcon = "settings.userIcon"
    static let hideBalance = "settings.hideBalance"
    static let currencySymbol = "settings.currencySymbol"
    static let decimalPlaces = "settings.decimalPlaces"
    static let paymentRemindersEnabled = "settings.paymentRemindersEnabled"
    static let reminderDaysBefore = "settings.reminderDaysBefore"

    // Eski tek-toggle anahtar (geri uyumluluk için kalıyor — yeni kod kullanmıyor)
    static let requireBiometric = "settings.requireBiometric"

    // Yeni güvenlik modeli
    static let securityMode = "settings.securityMode"  // SecurityMode.rawValue
    static let passcodeHash = "settings.passcodeHash"  // hex SHA256(salt+code)
}

// MARK: - Security Mode
enum SecurityMode: String, CaseIterable, Identifiable {
    case faceID   = "faceID"    // sadece biyometri
    case passcode = "passcode"  // sadece 4 haneli şifre

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .faceID:   return "Face ID / Touch ID"
        case .passcode: return "Şifre (4 hane)"
        }
    }

    var description: String {
        switch self {
        case .faceID:   return "Cihazın biyometrik kimliği ile açılır."
        case .passcode: return "Belirleyeceğiniz 4 haneli şifre ile açılır."
        }
    }

    var icon: String {
        switch self {
        case .faceID:   return "faceid"
        case .passcode: return "lock.fill"
        }
    }

    /// Şifre belirlemesi gereken mod mu?
    var requiresPasscode: Bool { self == .passcode }
    /// Biyometri gereken mod mu?
    var requiresBiometric: Bool { self == .faceID }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(PriceStore.self) private var priceStore

    // Persisted user preferences
    @AppStorage(SettingsKeys.userName) private var userName: String = "Kullanıcı"
    @AppStorage(SettingsKeys.lastName) private var lastName: String = ""
    @AppStorage(SettingsKeys.userIcon) private var userIcon: String = "person.crop.circle.fill"
    @AppStorage(SettingsKeys.hideBalance) private var hideBalance: Bool = false
    @AppStorage(SettingsKeys.currencySymbol) private var currencySymbol: String = "₺"
    @AppStorage(SettingsKeys.decimalPlaces) private var decimalPlaces: Int = 2
    @AppStorage(SettingsKeys.paymentRemindersEnabled) private var paymentRemindersEnabled: Bool = true
    @AppStorage(SettingsKeys.reminderDaysBefore) private var reminderDaysBefore: Int = 1
    @AppStorage(SettingsKeys.securityMode) private var securityModeRaw: String = SecurityMode.faceID.rawValue

    // Local UI state
    @State private var showingDeleteAllAlert = false
    @State private var showingDeleteReceiptsAlert = false
    @State private var showingClearImagesAlert = false
    @State private var showingProfileEditor = false
    @State private var showingTransactionsSheet = false
    @State private var showingPendingNotificationsSheet = false
    @State private var showingPasscodeSetup = false
    @State private var passcodeSetupMode: PasscodeMode = .create
    @State private var pendingSecurityMode: SecurityMode? = nil
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingCount: Int = 0
    @State private var biometricMessage: String?
    @State private var testNotificationMessage: String?

    private let availableIcons = [
        "person.crop.circle.fill",
        "person.crop.square.fill",
        "face.smiling.fill",
        "star.circle.fill",
        "bolt.circle.fill",
        "heart.circle.fill",
        "leaf.circle.fill",
        "flame.circle.fill"
    ]

    // ¥ kaldırıldı çünkü JPY/TRY kuru elimizde yok — sadece dönüştürebildiklerimizi gösteriyoruz
    private let availableCurrencies: [(symbol: String, name: String)] = [
        ("₺", "Türk Lirası"),
        ("$", "ABD Doları"),
        ("€", "Euro"),
        ("£", "İngiliz Sterlini")
    ]

    // MARK: Computed counts (used in subtitles and alerts)
    private var totalCount: Int { viewModel.transactions.count }
    private var receiptCount: Int { viewModel.transactions.filter { $0.receiptID != nil }.count }
    private var imageCount: Int { viewModel.transactions.compactMap { $0.receiptImagePath }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileCard
                appearanceCard
                notificationsCard
                securityCard
                dataCard
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .midnightTheme()
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            refreshNotificationStatus()
            refreshPendingCount()
        }
        .sheet(isPresented: $showingPendingNotificationsSheet, onDismiss: refreshPendingCount) {
            PendingNotificationsSheet()
        }
        .sheet(isPresented: $showingProfileEditor) {
            ProfileEditorSheet(
                userName: $userName,
                lastName: $lastName,
                userIcon: $userIcon,
                availableIcons: availableIcons
            )
        }
        .sheet(isPresented: $showingTransactionsSheet) {
            TransactionsListSheet(viewModel: viewModel)
        }
        .alert("Tüm İşlemleri Sil?", isPresented: $showingDeleteAllAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil (\(totalCount))", role: .destructive) { deleteAllTransactions() }
        } message: {
            Text("\(totalCount) gelir/gider kaydı ve bağlı fiş görselleri kalıcı olarak silinecek. Bu işlem geri alınamaz.")
        }
        .alert("Tüm Fişleri Sil?", isPresented: $showingDeleteReceiptsAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil (\(receiptCount))", role: .destructive) { deleteAllReceipts() }
        } message: {
            Text("\(receiptCount) fiş kaydı ve görselleri silinecek.")
        }
        .alert("Fiş Görsellerini Temizle?", isPresented: $showingClearImagesAlert) {
            Button("İptal", role: .cancel) {}
            Button("Temizle (\(imageCount))", role: .destructive) { clearReceiptImages() }
        } message: {
            Text("\(imageCount) görsel silinir, işlem kayıtları korunur.")
        }
    }

    // MARK: - Cards

    private var fullName: String {
        let combined = "\(userName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? "Kullanıcı" : combined
    }

    private var profileCard: some View {
        SettingsCard(title: "Profil", icon: "person.fill", iconColor: .neonBlue) {
            Button(action: { showingProfileEditor = true }) {
                HStack(spacing: 14) {
                    Image(systemName: userIcon)
                        .font(.system(size: 44))
                        .foregroundColor(.neonBlue)
                        .shadow(color: .neonBlue.opacity(0.5), radius: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fullName)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text("Düzenlemek için dokun")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    private var appearanceCard: some View {
        SettingsCard(title: "Görünüm & Biçim", icon: "paintpalette.fill", iconColor: .neonPurple) {
            VStack(spacing: 14) {
                Toggle(isOn: $hideBalance) {
                    SettingsRowLabel(icon: "eye.slash.fill", title: "Bakiyeyi Gizle", subtitle: "Ana ekranda bakiye ve varlıklar yıldızlanır")
                }
                .tint(.neonPurple)

                Divider().background(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 10) {
                    SettingsRowLabel(
                        icon: "arrow.left.arrow.right.circle.fill",
                        title: "Para Birimi",
                        subtitle: priceStore.hasRates ? "Canlı kurla TL'den dönüştürülür" : "Kur bilgisi yükleniyor…"
                    )
                    Picker("Para Birimi", selection: $currencySymbol) {
                        ForEach(availableCurrencies, id: \.symbol) { item in
                            Text("\(item.symbol)  \(item.name)").tag(item.symbol)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.neonBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                }

                Divider().background(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 10) {
                    SettingsRowLabel(icon: "number", title: "Ondalık Basamak", subtitle: "Tutarlardaki kuruş hassasiyeti")
                    Picker("Ondalık", selection: $decimalPlaces) {
                        Text("0  (1.000)").tag(0)
                        Text("2  (1.000,00)").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var notificationsCard: some View {
        SettingsCard(title: "Bildirimler", icon: "bell.fill", iconColor: .neonGreen) {
            VStack(spacing: 14) {
                Toggle(isOn: $paymentRemindersEnabled) {
                    SettingsRowLabel(icon: "calendar.badge.clock", title: "Ödeme Hatırlatmaları", subtitle: "Yaklaşan ödemeler için bildirim")
                }
                .tint(.neonGreen)
                .onChange(of: paymentRemindersEnabled) { _, newValue in
                    if !newValue {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                }

                if paymentRemindersEnabled {
                    Divider().background(Color.white.opacity(0.08))

                    VStack(alignment: .leading, spacing: 10) {
                        SettingsRowLabel(icon: "clock.fill", title: "Kaç Gün Önce", subtitle: "Hatırlatmanın geleceği gün sayısı")
                        Picker("Gün", selection: $reminderDaysBefore) {
                            Text("1 gün").tag(1)
                            Text("2 gün").tag(2)
                            Text("3 gün").tag(3)
                            Text("7 gün").tag(7)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Divider().background(Color.white.opacity(0.08))

                // Test notification button
                Button(action: sendTestNotification) {
                    SettingsActionRow(
                        icon: "paperplane.fill",
                        title: "Test Bildirimi Gönder",
                        subtitle: "5 saniye içinde bir test bildirimi gelir",
                        accent: .neonBlue,
                        chevron: false
                    )
                }
                .buttonStyle(.plain)

                if let testNotificationMessage {
                    Text(testNotificationMessage)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }

                Divider().background(Color.white.opacity(0.08))

                // Pending notifications list
                Button(action: { showingPendingNotificationsSheet = true }) {
                    SettingsActionRow(
                        icon: "list.bullet.rectangle",
                        title: "Bekleyen Bildirimler",
                        subtitle: "\(pendingCount) zamanlanmış bildirim — incele",
                        accent: .neonPurple
                    )
                }
                .buttonStyle(.plain)

                Divider().background(Color.white.opacity(0.08))

                HStack(spacing: 10) {
                    Image(systemName: notificationStatus == .authorized ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(notificationStatus == .authorized ? .neonGreen : .yellow)
                    Text(statusText(for: notificationStatus))
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                    Button("Sistem Ayarları") { openSystemSettings() }
                        .font(.footnote.bold())
                        .foregroundColor(.neonBlue)
                }
            }
        }
    }

    private var currentSecurityMode: SecurityMode {
        SecurityMode(rawValue: securityModeRaw) ?? .faceID
    }

    private var securityCard: some View {
        SettingsCard(title: "Güvenlik", icon: "lock.shield.fill", iconColor: .neonRed) {
            VStack(spacing: 12) {
                ForEach(SecurityMode.allCases) { mode in
                    Button(action: { handleModeChange(to: mode) }) {
                        HStack(spacing: 12) {
                            Image(systemName: mode.icon)
                                .foregroundColor(currentSecurityMode == mode ? .neonRed : .white)
                                .frame(width: 28, height: 28)
                                .background((currentSecurityMode == mode ? Color.neonRed : Color.white).opacity(currentSecurityMode == mode ? 0.18 : 0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            if currentSecurityMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.neonRed)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(mode.requiresBiometric && !biometricAvailable)
                    .opacity((mode.requiresBiometric && !biometricAvailable) ? 0.5 : 1)

                    if mode != SecurityMode.allCases.last {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }

                if currentSecurityMode.requiresPasscode && PasscodeManager.isSet {
                    Divider().background(Color.white.opacity(0.08))
                    Button(action: {
                        passcodeSetupMode = .change
                        showingPasscodeSetup = true
                    }) {
                        SettingsActionRow(
                            icon: "lock.rotation",
                            title: "Şifreyi Değiştir",
                            subtitle: "Mevcut şifrenizi yenisiyle değiştirin",
                            accent: .neonBlue
                        )
                    }
                    .buttonStyle(.plain)
                }

                if let biometricMessage {
                    Text(biometricMessage)
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .fullScreenCover(isPresented: $showingPasscodeSetup) {
            // Şifre belirleme/değiştirme ekranı
            PasscodeView(
                mode: passcodeSetupMode,
                onSuccess: {
                    showingPasscodeSetup = false
                    if let pending = pendingSecurityMode {
                        securityModeRaw = pending.rawValue
                        pendingSecurityMode = nil
                    }
                },
                onCancel: {
                    showingPasscodeSetup = false
                    pendingSecurityMode = nil   // mod değiştirme iptal edildi
                }
            )
        }
    }

    private var biometricAvailable: Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    private func handleModeChange(to newMode: SecurityMode) {
        biometricMessage = nil

        // Biyometri gerekiyorsa cihaz desteğini kontrol et
        if newMode.requiresBiometric && !biometricAvailable {
            biometricMessage = "Bu cihazda biyometrik kimlik kullanılamaz."
            return
        }

        // Şifre gerektiren moda geçilirken şifre yoksa kurma akışını başlat
        if newMode.requiresPasscode && !PasscodeManager.isSet {
            pendingSecurityMode = newMode
            passcodeSetupMode = .create
            showingPasscodeSetup = true
            return
        }

        // Şifre artık gerekmiyorsa hash'i temizleyelim
        if !newMode.requiresPasscode {
            PasscodeManager.save(nil)
        }

        securityModeRaw = newMode.rawValue
    }

    private var dataCard: some View {
        SettingsCard(title: "Veri Yönetimi", icon: "externaldrive.fill", iconColor: .yellow) {
            VStack(spacing: 0) {
                Button(action: { showingTransactionsSheet = true }) {
                    SettingsActionRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Toplam İşlem",
                        subtitle: "\(totalCount) kayıt — incelemek için dokun",
                        accent: .neonBlue
                    )
                }
                .buttonStyle(.plain)
                .disabled(totalCount == 0)
                .opacity(totalCount == 0 ? 0.5 : 1)

                Divider().background(Color.white.opacity(0.08))

                Button(action: { showingClearImagesAlert = true }) {
                    SettingsActionRow(
                        icon: "photo.on.rectangle.angled",
                        title: "Fiş Görsellerini Temizle",
                        subtitle: "\(imageCount) görsel silinir, kayıtlar korunur",
                        accent: .yellow
                    )
                }
                .buttonStyle(.plain)
                .disabled(imageCount == 0)
                .opacity(imageCount == 0 ? 0.5 : 1)

                Divider().background(Color.white.opacity(0.08))

                Button(action: { showingDeleteReceiptsAlert = true }) {
                    SettingsActionRow(
                        icon: "trash",
                        title: "Tüm Fişleri Sil",
                        subtitle: "\(receiptCount) fiş ve görselleri kaldırılır",
                        accent: .orange
                    )
                }
                .buttonStyle(.plain)
                .disabled(receiptCount == 0)
                .opacity(receiptCount == 0 ? 0.5 : 1)

                Divider().background(Color.white.opacity(0.08))

                Button(action: { showingDeleteAllAlert = true }) {
                    SettingsActionRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Tüm Verileri Sil",
                        subtitle: "\(totalCount) gelir/gider + bağlı fişler",
                        accent: .neonRed
                    )
                }
                .buttonStyle(.plain)
                .disabled(totalCount == 0)
                .opacity(totalCount == 0 ? 0.5 : 1)
            }
        }
    }

    // MARK: - Helpers

    private func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { notificationStatus = settings.authorizationStatus }
        }
    }

    private func refreshPendingCount() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async { pendingCount = requests.count }
        }
    }

    private func statusText(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized, .provisional, .ephemeral: return "Sistem izni: Verildi"
        case .denied: return "Sistem izni: Reddedildi"
        case .notDetermined: return "Sistem izni: Belirsiz"
        @unknown default: return "Bilinmeyen durum"
        }
    }

    private func sendTestNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                    testNotificationMessage = "Bildirim izni yok. Önce sistem ayarlarından izin verin."
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = "FinMate Test"
                content.body = "Bildirimler çalışıyor ✅ — bu bir test mesajıdır."
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "finmate.test.\(UUID().uuidString)", content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    DispatchQueue.main.async {
                        if let error {
                            testNotificationMessage = "Hata: \(error.localizedDescription)"
                        } else {
                            testNotificationMessage = "Test bildirimi 5 saniye içinde gelecek (uygulama açıkken de görünür)."
                            refreshPendingCount()
                        }
                    }
                }
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func deleteAllTransactions() {
        viewModel.deleteAllTransactions()
    }

    private func deleteAllReceipts() {
        viewModel.deleteAllReceipts()
    }

    private func clearReceiptImages() {
        viewModel.clearAllReceiptImages()
    }
}

// MARK: - Reusable building blocks

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SettingsRowLabel: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

private struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    var chevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(accent)
                .frame(width: 28, height: 28)
                .background(accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Profile Editor Sheet

private struct ProfileEditorSheet: View {
    @Binding var userName: String
    @Binding var lastName: String
    @Binding var userIcon: String
    let availableIcons: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var draftFirstName: String = ""
    @State private var draftLastName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    Image(systemName: userIcon)
                        .font(.system(size: 80))
                        .foregroundColor(.neonBlue)
                        .shadow(color: .neonBlue.opacity(0.5), radius: 14)
                        .padding(.top, 30)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ad")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Adınız", text: $draftFirstName)
                            .textContentType(.givenName)
                            .neoTextField()

                        Text("Soyad")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 6)
                        TextField("Soyadınız", text: $draftLastName)
                            .textContentType(.familyName)
                            .neoTextField()
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Avatar")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: { userIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 60)
                                        .background(userIcon == icon ? Color.neonBlue.opacity(0.3) : Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(userIcon == icon ? Color.neonBlue : Color.white.opacity(0.1), lineWidth: 1.5)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        let f = draftFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let l = draftLastName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !f.isEmpty { userName = f }
                        lastName = l
                        dismiss()
                    }
                    .foregroundColor(.neonBlue)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                draftFirstName = userName == "Kullanıcı" ? "" : userName
                draftLastName = lastName
            }
        }
    }
}

// MARK: - Transactions List Sheet

private struct TransactionsListSheet: View {
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(PriceStore.self) private var priceStore

    @AppStorage(SettingsKeys.currencySymbol) private var currencySymbol: String = "₺"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightBackground.ignoresSafeArea()

                if viewModel.transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Henüz hiç işlem yok")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.transactions) { tx in
                                TransactionRow(
                                    transaction: tx,
                                    convertedAmount: priceStore.convertFromTRY(tx.amount, toSymbol: currencySymbol),
                                    currencySymbol: currencySymbol
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Tüm İşlemler (\(viewModel.transactions.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(.neonBlue)
                }
            }
        }
    }
}

private struct TransactionRow: View {
    let transaction: TransactionEntity
    let convertedAmount: Double
    let currencySymbol: String

    private var isIncome: Bool {
        transaction.type == TransactionType.income.rawValue
    }

    private var amountText: String {
        let sign = isIncome ? "+" : "-"
        let displaySymbol = currencySymbol == "₺" ? "TL" : currencySymbol
        return "\(sign)\(String(format: "%.2f", convertedAmount)) \(displaySymbol)"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isIncome ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                .font(.title3)
                .foregroundColor(isIncome ? .neonGreen : .neonRed)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title ?? "Başlıksız")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    if let cat = transaction.category, !cat.isEmpty {
                        Text(cat)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(4)
                    }
                    Text(transaction.date ?? Date(), style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text(amountText)
                .font(.subheadline.weight(.bold))
                .foregroundColor(isIncome ? .neonGreen : .neonRed)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Pending Notifications Sheet

private struct PendingNotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var requests: [UNNotificationRequest] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.neonBlue)
                } else if requests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Zamanlanmış bildirim yok")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Ödeme Takvimi'nden bir ödeme eklediğinizde\nburada görünecek.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(requests, id: \.identifier) { req in
                                PendingNotificationRow(request: req)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Bekleyen Bildirimler (\(requests.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !requests.isEmpty {
                        Button(role: .destructive) {
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            load()
                        } label: {
                            Text("Tümünü Sil")
                                .foregroundColor(.neonRed)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(.neonBlue)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        isLoading = true
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            DispatchQueue.main.async {
                requests = reqs.sorted { ($0.identifier) < ($1.identifier) }
                isLoading = false
            }
        }
    }
}

private struct PendingNotificationRow: View {
    let request: UNNotificationRequest

    private var nextFireDateText: String {
        if let calTrigger = request.trigger as? UNCalendarNotificationTrigger,
           let next = calTrigger.nextTriggerDate() {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            f.locale = Locale(identifier: "tr_TR")
            return f.string(from: next) + (calTrigger.repeats ? "  •  Tekrar eder" : "")
        }
        if let timeTrigger = request.trigger as? UNTimeIntervalNotificationTrigger {
            let secs = Int(timeTrigger.timeInterval)
            return "\(secs) sn sonra" + (timeTrigger.repeats ? "  •  Tekrar eder" : "")
        }
        return "Zaman bilgisi yok"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .foregroundColor(.neonGreen)
                .frame(width: 28, height: 28)
                .background(Color.neonGreen.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(request.content.title.isEmpty ? request.identifier : request.content.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(nextFireDateText)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(request.identifier)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: TransactionViewModel())
    }
}
