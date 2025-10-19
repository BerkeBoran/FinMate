//
//  AddPaymentView.swift
//  FinMate
//
//  Created by Berke Boran on 19.10.2025.
//

import Foundation
import SwiftUI

struct AddPaymentView: View {
    @ObservedObject var viewModel: PaymentScheduleViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var recurring = false
    @State private var repeatType = "Aylık"
    
    private let repeatOptions = ["Haftalık", "Aylık", "Yıllık"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ödeme Bilgileri")) {
                    TextField("Başlık (Kira, Netflix...)", text: $title)
                    
                    TextField("Tutar", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Son Ödeme Tarihi", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Tekrarlama")) {
                    Toggle("Tekrar Eden Ödeme", isOn: $recurring)
                    
                    if recurring {
                        Picker("Tekrar Tipi", selection: $repeatType) {
                            ForEach(repeatOptions, id: \.self) { type in
                                Text(type.capitalized)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Yeni Ödeme Ekle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        if let amountValue = Double(amount) {
                            viewModel.addPayment(
                                title: title,
                                amount: amountValue,
                                lastPaymentDate: date,
                                recurring: recurring,
                                repeatType: repeatType
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

