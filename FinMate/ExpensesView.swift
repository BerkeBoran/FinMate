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
                ForEach(viewModel.transactions.filter { $0.type == .expense }) { transaction in
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(transaction.title)
                                .font(.headline)
                            Text(transaction.date, style: .date)
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

