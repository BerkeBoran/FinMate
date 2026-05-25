//
//  NotificationManager.swift
//  FinMate
//
//  Created by Berke Boran on 22.10.2025.
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() { super.init() }

    /// Uygulama başlangıcında çağrılır: delegate'i bağlar ve izin ister.
    func bootstrap() {
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Bildirim izni hatası: \(error.localizedDescription)")
            } else {
                print("Bildirim izni: \(granted ? "Verildi" : "Reddedildi")")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Uygulama ön plandayken de bildirim banner+ses ile gözüksün.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    /// Kullanıcı bildirime dokunduğunda çağrılır (şu an default davranış yeterli).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    // MARK: - Smart Reminder API (yeni — PaymentScheduleViewModel kullanır)

    /// Kullanıcı ayarlarından hatırlatma günü sayısı. Yoksa 1 gün önce.
    private var reminderDaysBefore: Int {
        let v = UserDefaults.standard.object(forKey: "settings.reminderDaysBefore") as? Int ?? 1
        return max(1, v)
    }

    /// Bir ödeme için hatırlatma planlar. recurring true ise her ay aynı günde tekrarlar.
    /// Tek seferlik durumda ABSOLUTE tarih kullanır (yıl+ay+gün+saat) — yanlış aya kaymaz.
    func scheduleReminder(for title: String, amount: Double, paymentDate: Date, recurring: Bool, identifier: String? = nil) {
        let calendar = Calendar.current
        let daysBefore = reminderDaysBefore

        guard let reminderDate = calendar.date(byAdding: .day, value: -daysBefore, to: paymentDate) else { return }

        // İçerik
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        let content = UNMutableNotificationContent()
        content.title = "Yaklaşan \(title) ödemesi"
        content.body = "\(formatter.string(from: paymentDate)) tarihindeki \(String(format: "%.2f", amount)) ₺ ödemenizi unutmayın."
        content.sound = .default

        let id = identifier ?? "payment.\(title).\(Int(paymentDate.timeIntervalSince1970))"

        // Trigger
        let trigger: UNNotificationTrigger
        if recurring {
            // Her ay aynı günde tekrarla (gün + saat)
            var comps = DateComponents()
            comps.day = calendar.component(.day, from: reminderDate)
            comps.hour = calendar.component(.hour, from: reminderDate)
            comps.minute = calendar.component(.minute, from: reminderDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        } else {
            // Tek seferlik: ABSOLUTE tarih
            // Geçmiş tarih olmasın diye kontrol et
            guard reminderDate > Date() else {
                print("⚠️ Hatırlatma tarihi (\(reminderDate)) geçmişte, atlanıyor.")
                return
            }
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        }

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Hatırlatma planlanırken hata: \(error.localizedDescription)")
            } else {
                print("✅ Hatırlatma planlandı: \(id) — tetik: \(reminderDate)")
            }
        }
    }
    func scheduleRepeatingNotificationsWeekly(for title: String, amount: Double, lastPaymentDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        
        let formattedDate = formatter.string(from: lastPaymentDate)
        
        let content = UNMutableNotificationContent()
        content.title = "Yaklaşan \(title) ödemesi"
        content.body = " \(formattedDate)Tarihindeki \(String(format: "%.2f", amount)) tutarındaki ödemenizi hatırlatmak istedik iyi günler."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastPaymentDate)
        guard let day = components.day else { return }
        
        
        var oneDayBefore = DateComponents()
        oneDayBefore.day = (day - 1 <= 0) ? 1 : day - 1
        oneDayBefore.hour = 12
        
        let dayTrigger = UNCalendarNotificationTrigger(dateMatching: oneDayBefore, repeats: true)
        
        
        let dayRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-day",
            content: content,
            trigger: dayTrigger
        )
        
        UNUserNotificationCenter.current().add(dayRequest) { error in
            if let error = error { print("Günlük bildirim hatası: \(error)") }
        }
        
    }
    func scheduleNotificationWeekly(for title: String, amount: Double, lastPaymentDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        let formattedDate = formatter.string(from: lastPaymentDate)
        
        let content = UNMutableNotificationContent()
        content.title = "Yaklaşan \(title) ödemesi"
        content.body = "\(formattedDate) tarihindeki \(String(format: "%.2f", amount)) ₺ tutarındaki ödemenizi hatırlatmak istedik İyi günler."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastPaymentDate)
        guard let day = components.day else { return }
        
        
        var oneDayBefore = DateComponents()
        oneDayBefore.day = (day - 1 <= 0) ? 1 : day - 1
        oneDayBefore.hour = 12
        let dayTrigger = UNCalendarNotificationTrigger(dateMatching: oneDayBefore, repeats: false)
        
        let dayRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-day",
            content: content,
            trigger: dayTrigger
        )
        
        UNUserNotificationCenter.current().add(dayRequest) { error in
            if let error = error { print("Günlük bildirim hatası: \(error)") }
        }
    }
    
    func scheduleRepeatingNotificationsMonthly(for title: String, amount: Double, lastPaymentDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        
        let formattedDate = formatter.string(from: lastPaymentDate)
        
        let content = UNMutableNotificationContent()
        content.title = "Yaklaşan \(title) ödemesi"
        content.body = " \(formattedDate)Tarihindeki \(String(format: "%.2f", amount)) tutarındaki ödemenizi hatırlatmak istedik iyi günler."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastPaymentDate)
        guard let day = components.day else { return }
        
        var oneWeekBefore = DateComponents()
        oneWeekBefore.day = (day - 7 <= 0) ? 1 : day - 7
        oneWeekBefore.hour = 12
        let weekTrigger = UNCalendarNotificationTrigger(dateMatching: oneWeekBefore, repeats: true)
        
        var oneDayBefore = DateComponents()
        oneDayBefore.day = (day - 1 <= 0) ? 1 : day - 1
        oneDayBefore.hour = 12
        let dayTrigger = UNCalendarNotificationTrigger(dateMatching: oneDayBefore, repeats: true)
        
        let weekRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-week",
            content: content,
            trigger: weekTrigger
        )
        
        let dayRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-day",
            content: content,
            trigger: dayTrigger
        )
        
        UNUserNotificationCenter.current().add(weekRequest) { error in
            if let error = error { print("Haftalık bildirim hatası: \(error)") }
        }
        
        UNUserNotificationCenter.current().add(dayRequest) { error in
            if let error = error { print("Günlük bildirim hatası: \(error)") }
        }
        
    }
    func scheduleNotificationMonthly(for title: String, amount: Double, lastPaymentDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        let formattedDate = formatter.string(from: lastPaymentDate)
        
        let content = UNMutableNotificationContent()
        content.title = "Yaklaşan \(title) ödemesi"
        content.body = "\(formattedDate) tarihindeki \(String(format: "%.2f", amount)) ₺ tutarındaki ödemenizi hatırlatmak istedik İyi günler."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastPaymentDate)
        guard let day = components.day else { return }
        
        var oneWeekBefore = DateComponents()
        oneWeekBefore.day = (day - 7 <= 0) ? 1 : day - 7
        oneWeekBefore.hour = 12
        let weekTrigger = UNCalendarNotificationTrigger(dateMatching: oneWeekBefore, repeats: false)
        
        var oneDayBefore = DateComponents()
        oneDayBefore.day = (day - 1 <= 0) ? 1 : day - 1
        oneDayBefore.hour = 12
        let dayTrigger = UNCalendarNotificationTrigger(dateMatching: oneDayBefore, repeats: false)
        
        let weekRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-week",
            content: content,
            trigger: weekTrigger
        )
        
        let dayRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-day",
            content: content,
            trigger: dayTrigger
        )
        
        UNUserNotificationCenter.current().add(weekRequest) { error in
            if let error = error { print("Haftalık bildirim hatası: \(error)") }
        }
        
        UNUserNotificationCenter.current().add(dayRequest) { error in
            if let error = error { print("Günlük bildirim hatası: \(error)") }
        }
    }
    func scheduleRepeatingNotificationsYearly(for title: String, amount: Double, lastPaymentDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        
        let formattedDate = formatter.string(from: lastPaymentDate)
        
        let content = UNMutableNotificationContent()
        content.title = "Yaklaşan \(title) ödemesi"
        content.body = " \(formattedDate)Tarihindeki \(String(format: "%.2f", amount)) tutarındaki ödemenizi hatırlatmak istedik iyi günler."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastPaymentDate)
        guard let day = components.day else { return }
        
        var oneMonthBefore = DateComponents()
        oneMonthBefore.day = (day - 30 <= 0) ? 1 : day - 30
        oneMonthBefore.hour = 12
        let monthTrigger = UNCalendarNotificationTrigger(dateMatching: oneMonthBefore, repeats: true)
        
        var oneWeekBefore = DateComponents()
        oneWeekBefore.day = (day - 7 <= 0) ? 1 : day - 7
        oneWeekBefore.hour = 12
        let weekTrigger = UNCalendarNotificationTrigger(dateMatching: oneWeekBefore, repeats: true)
        
        var oneDayBefore = DateComponents()
        oneDayBefore.day = (day - 1 <= 0) ? 1 : day - 1
        oneDayBefore.hour = 12
        let dayTrigger = UNCalendarNotificationTrigger(dateMatching: oneDayBefore, repeats: true)
        
        let monthRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-month",
            content: content,
            trigger: monthTrigger
        )
        
        
        
        let weekRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-week",
            content: content,
            trigger: weekTrigger
        )
        
        let dayRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-day",
            content: content,
            trigger: dayTrigger
        )
        
        UNUserNotificationCenter.current().add(weekRequest) { error in
            if let error = error { print("Haftalık bildirim hatası: \(error)") }
        }
        
        UNUserNotificationCenter.current().add(dayRequest) { error in
            if let error = error { print("Günlük bildirim hatası: \(error)") }
        }
        UNUserNotificationCenter.current().add(monthRequest) { error in
            if let error = error { print("Aylık bildirim hatası: \(error)") }
        }
        
    }
    func scheduleNotificationYearly(for title: String, amount: Double, lastPaymentDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        let formattedDate = formatter.string(from: lastPaymentDate)
        
        let content = UNMutableNotificationContent()
        content.title = "Yaklaşan \(title) ödemesi"
        content.body = "\(formattedDate) tarihindeki \(String(format: "%.2f", amount)) ₺ tutarındaki ödemenizi hatırlatmak istedik İyi günler."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastPaymentDate)
        guard let day = components.day else { return }
        
        var oneMonthBefore = DateComponents()
        oneMonthBefore.day = (day - 30 <= 0) ? 1 : day - 30
        oneMonthBefore.hour = 12
        let monthTrigger = UNCalendarNotificationTrigger(dateMatching: oneMonthBefore, repeats: false)
        
        var oneWeekBefore = DateComponents()
        oneWeekBefore.day = (day - 7 <= 0) ? 1 : day - 7
        oneWeekBefore.hour = 12
        let weekTrigger = UNCalendarNotificationTrigger(dateMatching: oneWeekBefore, repeats: false)
        
        var oneDayBefore = DateComponents()
        oneDayBefore.day = (day - 1 <= 0) ? 1 : day - 1
        oneDayBefore.hour = 12
        let dayTrigger = UNCalendarNotificationTrigger(dateMatching: oneDayBefore, repeats: false)
        
        let monthRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-month",
            content: content,
            trigger: monthTrigger
        )
        
        
        let weekRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-week",
            content: content,
            trigger: weekTrigger
        )
        
        let dayRequest = UNNotificationRequest(
            identifier: "\(title)-monthly-day",
            content: content,
            trigger: dayTrigger
        )
        UNUserNotificationCenter.current().add(monthRequest) { error in
            if let error = error { print("Aylık bildirim hatası: \(error)") }
        }
        
        UNUserNotificationCenter.current().add(weekRequest) { error in
            if let error = error { print("Haftalık bildirim hatası: \(error)") }
        }
        
        UNUserNotificationCenter.current().add(dayRequest) { error in
            if let error = error { print("Günlük bildirim hatası: \(error)") }
        }
    }
}
