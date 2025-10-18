//
//  ExpensesView.swift
//  FinMate
//
//  Created by Berke Boran on 9.10.2025.
//

import SwiftUI

struct ExpensesView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.transactions.filter { $0.type == TransactionType.expense.rawValue }) { transaction in
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(transaction.title ?? "Başlıksız")
                                .font(.headline)
                            Text(transaction.date ?? Date(), style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("-\(transaction.amount, specifier: "%.2f") TL")
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 5)
                }
                .onDelete(perform: viewModel.deleteTransaction)
            }
            .navigationTitle("Harcamalar")
        }
    }
}

#Preview {
    ExpensesView(viewModel: TransactionViewModel())
}

