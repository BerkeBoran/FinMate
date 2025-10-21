//
//  NotificationManager.swift
//  FinMate
//
//  Created by Berke Boran on 22.10.2025.
//

import Foundation
import UserNotifications
class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Bildirim izni hatası: \(error.localizedDescription)")
            } else {
                print("Bildirim izni: \(granted ? "Verildi" : "Reddedildi")")
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
