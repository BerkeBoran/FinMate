//
//  PaymentScheduleViewModel.swift
//  FinMate
//
//  Created by Berke Boran on 19.10.2025.
//

import Foundation
import CoreData
class PaymentScheduleViewModel:ObservableObject {
    @Published var paymentSchedule: [PaymentScheduleEntity] = []
    let context = PersistenceController.shared.container.viewContext
    func fetchPayments() {
        let request = NSFetchRequest<PaymentScheduleEntity>(entityName: "PaymentScheduleEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentScheduleEntity.lastPaymentDate, ascending: true)]
        
        do {
            paymentSchedule = try context.fetch(request)
        } catch {
            print("Ödeme verisi çekme hatası: \(error.localizedDescription)")
        }
    }
    init() {
        fetchPayments()
    }
    func save() {
        do {
            try context.save()
            fetchPayments()
        } catch {
            print("Ödeme kayıt edilme hatası: \(error.localizedDescription)")
        }
    }
    
    /// Kullanıcının Ayarlar'dan açtığı bildirim tercihi.
    private var remindersEnabled: Bool {
        // Varsayılan true: anahtar tanımlı değilse aktif kabul ederiz.
        UserDefaults.standard.object(forKey: "settings.paymentRemindersEnabled") as? Bool ?? true
    }

    func addPayment(title: String, amount: Double, lastPaymentDate: Date, recurring: Bool, repeatType: String) {
        let newPayment = PaymentScheduleEntity(context: context)
        newPayment.id = UUID()
        newPayment.title = title
        newPayment.amount = amount
        newPayment.lastPaymentDate = lastPaymentDate
        newPayment.recurring = recurring
        newPayment.repeatType = repeatType
        save()

        // Bildirimler kapalıysa hiç zamanlama yapmadan çık.
        guard remindersEnabled else { return }

        // Tek temiz metoda yönlendiriyoruz: kullanıcının "kaç gün önce" tercihini
        // ve mutlak tarih bilgisini kullanır, böylece yanlış aya/yıla kaymaz.
        let id = newPayment.id?.uuidString ?? "\(title)-\(Int(lastPaymentDate.timeIntervalSince1970))"
        NotificationManager.shared.scheduleReminder(
            for: title,
            amount: amount,
            paymentDate: lastPaymentDate,
            recurring: recurring,
            identifier: id
        )
    }
        
        
        func deletePayment(at offsets: IndexSet) {
            offsets.forEach { index in
                let paymentSchedule = paymentSchedule[index]
                context.delete(paymentSchedule)
            }
            save()
        }
        func getPaymentSchedule() -> [(date: Date, amount: Double, title: String)] {
            return paymentSchedule.map { paymentSchedule in
                (paymentSchedule.lastPaymentDate ?? Date(), paymentSchedule.amount, paymentSchedule.title ?? "")
            }
            .sorted { $0.0 < $1.0 }
        }
        
}
