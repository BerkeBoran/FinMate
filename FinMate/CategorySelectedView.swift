//
//  CategorySelectedView.swift
//  FinMate
//
//  Created by Berke Boran on 11.10.2025.
//

import SwiftUI
struct CategorySelectedView: View {
    @ObservedObject var viewModel: TransactionViewModel
    var category: String
    
    @State private var period: Calendar.Component = .day
    @State private var selectedDate = Date()
    var body: some View {
        VStack(alignment: .leading) {
            Text(category=="Diğer" ? "\(category) Harcamalar" : "\(category) Harcamaları")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Picker("Tarih", selection: $period) {
                Text("Gün").tag(Calendar.Component.day)
                Text("Ay").tag(Calendar.Component.month)
                Text("Yıl").tag(Calendar.Component.year)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            DatePicker("Gün Seçin", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .padding(.horizontal)
            
            let total = viewModel.totalAmount(for: category, period: period, referenceDate: selectedDate)
            Text("Toplam: \(total, specifier: "%.2f")")
                .font(.title2)
                .padding()
            List(viewModel.transactions(for: category)) { tx in
                HStack {
                    Text(tx.title)
                    Spacer()
                    Text("\(tx.amount, specifier: "%.2f")")
                    Text(tx.date, style: .date)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
        .navigationTitle(category)
    }    }

