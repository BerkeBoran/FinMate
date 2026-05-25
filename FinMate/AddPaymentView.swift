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
        ZStack {
            // Background
            Color.midnightBackground.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header
                Text("Yeni Ödeme Ekle")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top)
                    .shadow(color: .neonBlue.opacity(0.5), radius: 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Section 1: Info
                        VStack(alignment: .leading, spacing: 15) {
                            Text("ÖDEME BİLGİLERİ")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.gray)
                                .padding(.leading, 5)
                            
                            TextField("Başlık (Kira, Netflix...)", text: $title)
                                .neoTextField()
                            
                            TextField("Tutar", text: $amount)
                                .keyboardType(.decimalPad)
                                .neoTextField()
                            
                            HStack {
                                Text("Tarih")
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            .padding()
                            .background(Color.surface.opacity(0.5))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding()
                        .glassCard()
                        
                        // Section 2: Recurring
                        VStack(alignment: .leading, spacing: 15) {
                            Toggle("Tekrar Eden Ödeme", isOn: $recurring)
                                .toggleStyle(SwitchToggleStyle(tint: .neonBlue))
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 5)
                            
                            if recurring {
                                Divider().background(Color.white.opacity(0.1))
                                
                                Text("TEKRAR TİPİ")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.gray)
                                    .padding(.top, 5)
                                    .padding(.leading, 5)
                                
                                HStack(spacing: 10) {
                                    ForEach(repeatOptions, id: \.self) { type in
                                        Button(action: {
                                            withAnimation { repeatType = type }
                                        }) {
                                            Text(type)
                                                .font(.subheadline)
                                                .bold()
                                                .padding(.vertical, 10)
                                                .frame(maxWidth: .infinity)
                                                .background(repeatType == type ? Color.neonBlue.opacity(0.3) : Color.clear)
                                                .foregroundColor(repeatType == type ? .neonBlue : .gray)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(repeatType == type ? Color.neonBlue : Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .glassCard()
                    }
                    .padding(.horizontal)
                }
                
                // Actions
                HStack(spacing: 15) {
                    Button(action: { dismiss() }) {
                        Text("Vazgeç")
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
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
                    }) {
                        Text("Kaydet")
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(colors: [.neonBlue, .neonPurple], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(15)
                            .foregroundColor(.white)
                            .shadow(color: .neonBlue.opacity(0.5), radius: 10)
                    }
                    .disabled(title.isEmpty || amount.isEmpty)
                    .opacity((title.isEmpty || amount.isEmpty) ? 0.5 : 1)
                }
                .padding()
                .padding(.bottom)
            }
        }
    }
}
