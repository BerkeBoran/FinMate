//
//  Transaction.swift
//  FinMate
//
//  Created by Berke Boran on 8.10.2025.
//

import Foundation
enum TransactionType: String, Codable {
    case income = "Income"
    case expense = "Expense"
}

struct Transaction: Identifiable, Codable {
    var id = UUID() 
    var title: String
    var amount: Double
    var date: Date
    var type: TransactionType
}
