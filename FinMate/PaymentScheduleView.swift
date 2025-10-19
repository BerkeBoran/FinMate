//
//  PaymentScheduleView.swift
//  FinMate
//
//  Created by Berke Boran on 19.10.2025.
//

import Foundation
import SwiftUI

struct PaymentScheduleView: View {
    @StateObject var viewModel=PaymentScheduleViewModel()
    @State private var showAddPayment = false
    var body: some View {
        NavigationView{
            List{
                ForEach(viewModel.paymentSchedule, id: \.id) { payment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(payment.title ?? "Bilinmeyen")
                                .font(.headline)
                            
                            if let date = payment.lastPaymentDate {
                                Text(date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(payment.amount, specifier: "%.2f") ₺")
                            .font(.headline)
                    }
                }
                .onDelete(perform: viewModel.deletePayment)
            }
            .navigationTitle("Ödeme Takvimi")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddPayment = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddPayment) {
                AddPaymentView(viewModel: viewModel)
            }
        }
    }
}

