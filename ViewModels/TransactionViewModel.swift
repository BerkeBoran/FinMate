//
//  TransactionViewModel.swift
//  FinMate
//
//  Created by Berke Boran on 8.10.2025.
//

import Foundation
class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    func addTransaction(title: String, amount: Double, type: TransactionType) {
        let newTransaction = Transaction(title: title, amount: amount, date: Date(), type: type)
        transactions.append(newTransaction)
    }
    func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
    }
    
    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalIncome - totalExpense
    }
    func dailyReport() -> [(date: Date, income: Double, expense: Double)] {
                let grouped = Dictionary(grouping: transactions) { transaction in
                    let components = Calendar.current.dateComponents([.day,.year,.month], from: transaction.date)
                           return Calendar.current.date(from: components)!
                }
                
                return grouped.map { (date, transactions) in
                    let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    return (date, income, expense)
                }
                .sorted { $0.date > $1.date }
            }
    
    func monthlyReport() -> [(date: Date, income: Double, expense: Double)] {
                let grouped = Dictionary(grouping: transactions) { transaction in
                    let components = Calendar.current.dateComponents([.year,.month], from: transaction.date)
                           return Calendar.current.date(from: components)!
                }
                
                return grouped.map { (date, transactions) in
                    let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    return (date, income, expense)
                }
                .sorted { $0.date > $1.date }
            }
    func yearlyReport() -> [(date: Date, income: Double, expense: Double)] {
                let grouped = Dictionary(grouping: transactions) { transaction in
                    let components = Calendar.current.dateComponents([.year], from: transaction.date)
                           return Calendar.current.date(from: components)!
                }
                
                return grouped.map { (date, transactions) in
                    let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                    let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                    return (date, income, expense)
                }
                .sorted { $0.date > $1.date }
            }
}
