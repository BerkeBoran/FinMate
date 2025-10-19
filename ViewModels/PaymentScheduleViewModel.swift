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
    
    func addPayment(title: String, amount: Double, lastPaymentDate: Date, recurring: Bool, repeatType: String) {
           let newPayment = PaymentScheduleEntity(context: context)
           newPayment.id = UUID()
           newPayment.title = title
           newPayment.amount = amount
           newPayment.lastPaymentDate = lastPaymentDate
           newPayment.recurring = recurring
           newPayment.repeatType = repeatType
           save()
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
