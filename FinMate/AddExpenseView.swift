//
//  AddExpenseView.swift
//  FinMate
//
//  Created by Berke Boran on 8.10.2025.
//

import SwiftUI
struct AddExpenseView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State var amount:String = ""
    @State var title:String = ""
    var body: some View {
        VStack{
            Text("Güncel Bakiye: \(viewModel.balance, specifier: "%.2f")")
                .font(.title2)
                .bold()
                .padding(.top,40)
            VStack{
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
            .padding()
            Button(action: {
                if let amountDouble = Double(amount) {
                    viewModel.addTransaction(title: title, amount: amountDouble, type: .expense)
                    title = ""
                    amount = ""
                }
            }) {
                Text("Gider Ekle")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(15)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}
#Preview {
    AddExpenseView(viewModel:TransactionViewModel())
}
