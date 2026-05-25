//
//  AddExpenseView.swift
//  FinMate
//
//  Created by Berke Boran on 8.10.2025.
//

import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var selectedCategory: String = ExpenseCategories.list.first ?? "Diğer"
    @State private var customTitle: String = ""
    @State private var amount: String = ""

    private var isOther: Bool { selectedCategory == "Diğer" }

    var body: some View {
        VStack(spacing: 20) {
            Text("Güncel Bakiye: \(viewModel.balance, specifier: "%.2f") TL")
                .font(.title2)
                .bold()
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 15) {
                Text("Kategori")
                    .font(.headline)
                Picker("Kategori", selection: $selectedCategory) {
                    ForEach(ExpenseCategories.list, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                if isOther {
                    Text("Başlık")
                        .font(.headline)
                    TextField("Örn: Doğum Günü Hediyesi", text: $customTitle)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                }

                Text("Tutar")
                    .font(.headline)
                TextField("Örn: 1000", text: $amount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: addExpense) {
                Text("Gider Ekle")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(canSubmit ? Color.red : Color.red.opacity(0.4))
                    .cornerRadius(15)
                    .shadow(radius: 5)
            }
            .disabled(!canSubmit)
            .padding(.horizontal)

            Spacer()
        }
    }

    private var canSubmit: Bool {
        guard Double(amount.replacingOccurrences(of: ",", with: ".")) != nil else { return false }
        if isOther { return !customTitle.trimmingCharacters(in: .whitespaces).isEmpty }
        return true
    }

    private func addExpense() {
        guard let amt = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return }
        let title = isOther ? customTitle.trimmingCharacters(in: .whitespaces) : selectedCategory
        viewModel.addTransaction(title: title, amount: amt, type: .expense, category: selectedCategory)
        customTitle = ""
        amount = ""
    }
}

enum ExpenseCategories {
    static let list: [String] = [
        "Yemek",
        "Ulaşım",
        "Faturalar",
        "Market Alışverişi",
        "Eğlence",
        "Giyim",
        "Kira Ödemeleri",
        "Kredi Kartı Ödemeleri",
        "Diğer"
    ]
}

#Preview {
    AddExpenseView(viewModel: TransactionViewModel())
}
