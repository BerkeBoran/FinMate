//
//  TransactionViewModel.swift
//  FinMate
//
//  Created by Berke Boran on 8.10.2025.
//

import Foundation
import CoreData

class TransactionViewModel: ObservableObject {
    @Published var transactions: [TransactionEntity] = []
    let context = PersistenceController.shared.container.viewContext
    init() {
          fetchTransactions()
      }
    func fetchTransactions() {
           let request = NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
           request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
           
           do {
               transactions = try context.fetch(request)
           } catch {
               print("Veri çekerken Hata oldu: \(error.localizedDescription)")
           }
       }
    
    func save() {
        do {
            try context.save()
            fetchTransactions()
        } catch {
            print("Kayıt Hatası: \(error.localizedDescription)")
        }
    }

    
    func addTransaction(title: String,
                        amount: Double,
                        type: TransactionType,
                        category: String,
                        receiptID: UUID? = nil,
                        receiptImagePath: String? = nil) {
        let newTransaction = TransactionEntity(context: context)
        newTransaction.id = UUID()
        newTransaction.date = Date()
        newTransaction.title = title
        newTransaction.amount = amount
        newTransaction.type = type.rawValue
        newTransaction.category = category
        newTransaction.receiptID = receiptID
        newTransaction.receiptImagePath = receiptImagePath
        save()
     }
    func deleteTransaction(at offsets: IndexSet) {
        offsets.forEach { index in
              let transaction = transactions[index]
              context.delete(transaction)
          }
          save()
    }

    func deleteReceipt(_ receiptID: UUID) {
        let toDelete = transactions.filter { $0.receiptID == receiptID }
        let imagePath = toDelete.compactMap { $0.receiptImagePath }.first
        for tx in toDelete {
            context.delete(tx)
        }
        if let imagePath {
            ReceiptStorage.delete(imagePath)
        }
        save()
    }
    
    var totalIncome: Double {
        transactions.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        transactions.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalIncome - totalExpense
    }
    func dailyReport() -> [(date: Date, income: Double, expense: Double)] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            let components = Calendar.current.dateComponents([.day,.year,.month], from: transaction.date ?? Date())
            return Calendar.current.date(from: components)!
        }
        
        return grouped.map { (date, transactions) in
            let income = transactions.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
            let expense = transactions.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
            return (date, income, expense)
        }
        .sorted { $0.date > $1.date }
    }
    
    func monthlyReport() -> [(date: Date, income: Double, expense: Double)] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            let components = Calendar.current.dateComponents([.year,.month], from: transaction.date ?? Date())
            return Calendar.current.date(from: components)!
        }
        
        return grouped.map { (date, transactions) in
            let income = transactions.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
            let expense = transactions.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
            return (date, income, expense)
        }
        .sorted { $0.date > $1.date }
    }
    func yearlyReport() -> [(date: Date, income: Double, expense: Double)] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            let components = Calendar.current.dateComponents([.year], from: transaction.date ?? Date())
            return Calendar.current.date(from: components)!
        }
        
        return grouped.map { (date, transactions) in
            let income = transactions.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
            let expense = transactions.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
            return (date, income, expense)
        }
        .sorted { $0.date > $1.date }
    }
    func dailyIncomeExpense(for month: Date) -> [(day: Int, income: Double, expense: Double)] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<31
        let comps = calendar.dateComponents([.year, .month], from: month)
        let filtered = transactions.filter { calendar.isDate($0.date ?? Date(), equalTo: month, toGranularity: .month) }

        return range.map { day -> (Int, Double, Double) in
            var dc = DateComponents()
            dc.year = comps.year
            dc.month = comps.month
            dc.day = day
            let dayDate = calendar.date(from: dc)!
            let items = filtered.filter { calendar.isDate($0.date ?? Date(), inSameDayAs: dayDate) }
            let income = items.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
            let expense = items.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
            return (day, income, expense)
        }
    }

    func cumulativeBalanceMonthly(months: Int = 6) -> [(date: Date, balance: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var result: [(Date, Double)] = []

        let cutoffComps = calendar.dateComponents([.year, .month], from: now)
        guard let currentMonthStart = calendar.date(from: cutoffComps) else { return [] }

        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: currentMonthStart),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let endThreshold = min(monthEnd, now)
            let upto = transactions.filter { ($0.date ?? .distantPast) < endThreshold }
            let income = upto.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
            let expense = upto.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
            result.append((monthStart, income - expense))
        }
        return result
    }

    func dailyBarChart(for month: Date) -> [(date: Date, balance: Double)] {
        let calendar = Calendar.current
        let filtered = transactions.filter { calendar.isDate($0.date ?? Date(), equalTo: month, toGranularity: .month) }
        
        let grouped = Dictionary(grouping: filtered) { transaction in
            let components = calendar.dateComponents([.year, .month, .day], from: transaction.date ?? Date())
            return calendar.date(from: components)!
        }
        
        let range = calendar.range(of: .day, in: .month, for: month)!
        
        let dailyData = range.map { day -> (Date, Double) in
            let components = calendar.dateComponents([.year, .month], from: month)
            var dateComponents = DateComponents()
            dateComponents.year = components.year
            dateComponents.month = components.month
            dateComponents.day = day
            let dayDate = calendar.date(from: dateComponents)!
            
            let items = grouped[dayDate] ?? []
            let income = items.filter { $0.type == TransactionType.income.rawValue }.reduce(0) { $0 + $1.amount }
            let expense = items.filter { $0.type == TransactionType.expense.rawValue }.reduce(0) { $0 + $1.amount }
            let balance = income - expense
            
            return (dayDate, balance)
        }
        
        return dailyData.sorted { $0.0 < $1.0 }
    }
    
}
struct ReceiptSummary: Identifiable {
    let id: UUID
    let imagePath: String?
    let date: Date
    let itemCount: Int
    let total: Double
    let items: [TransactionEntity]
}

extension TransactionViewModel {

    func receipts() -> [ReceiptSummary] {
        let withReceipt = transactions.filter { $0.receiptID != nil }
        let grouped = Dictionary(grouping: withReceipt) { $0.receiptID! }
        return grouped.map { (id, items) in
            let total = items.reduce(0) { $0 + $1.amount }
            let date = items.map { $0.date ?? Date() }.max() ?? Date()
            let imagePath = items.compactMap { $0.receiptImagePath }.first
            return ReceiptSummary(id: id, imagePath: imagePath, date: date, itemCount: items.count, total: total, items: items)
        }
        .sorted { $0.date > $1.date }
    }

    func transactions(for category: String) -> [TransactionEntity] {
        transactions.filter { $0.category == category }
    }
    
    func totalAmount(for category: String, period: Calendar.Component, referenceDate: Date = Date()) -> Double {
        let calendar = Calendar.current
        let filtered = transactions(for: category).filter { tx in
            calendar.isDate(tx.date ?? Date(), equalTo: referenceDate, toGranularity: period)
        }
        return filtered.reduce(0) { $0 + $1.amount }
    }
}
//Silinecek Uygulama Çalışsın Diye Yazıldı
extension TransactionViewModel {
    func category(for title: String) -> String {
        let lowercasedTitle = title.lowercased()
        if lowercasedTitle.contains("yemek") || lowercasedTitle.contains("restaurant") {
            return "Yemek"
        } else if lowercasedTitle.contains("giyim") || lowercasedTitle.contains("elbise") {
            return "Giyim"
        } else if lowercasedTitle.contains("otobüs") || lowercasedTitle.contains("taxi") {
            return "Ulaşım"
        } else {
            return "Diğer"
        }
    }
}


