//
//  AddIncomeView.swift
//  FinMate
//
//  Created by Berke Boran on 8.10.2025.
//

import SwiftUI

struct AddIncomeView: View {
    @ObservedObject var viewModel: TransactionViewModel
    
    @State private var title: String = ""
    @State private var amount: String = ""    
    var body: some View {
        VStack(spacing: 20) {
                Text("Güncel Bakiye: \(viewModel.balance, specifier: "%.2f") TL")
                    .font(.title2)
                    .bold()
                    .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Başlık")
                        .font(.headline)
                    TextField("Örn: Maaş, Market Alışverişi", text: $title)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .textInputAutocapitalization(.sentences)
                            .disableAutocorrection(false)
                    
                    Text("Tutar")
                        .font(.headline)
                    TextField("Örn: 1000", text: $amount)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    if let amountDouble = Double(amount) {
                        viewModel.addTransaction(title: title, amount: amountDouble, type: .income)
                        title = ""
                        amount = ""
                    }
                }) {
                    Text("Gelir Ekle")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Gelir Ekle")
        }
    }
#Preview {
    AddIncomeView(viewModel:TransactionViewModel())
}
