//
//  ReportsView.swift
//  FinMate
//
//  Created by Berke Boran on 9.10.2025.
//

import SwiftUI

enum ReportType: String, CaseIterable {
    case daily = "Günlük"
    case monthly = "Aylık"
    case yearly = "Yıllık"
}

struct ReportsView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var showSheet = false
    @State private var selectedReport: ReportType = .daily
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    showSheet.toggle()
                }) {
                    HStack {
                        Text("Rapor Tipi: \(selectedReport.rawValue)")
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                .sheet(isPresented: $showSheet) {
                    VStack(spacing: 20) {
                        ForEach(ReportType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                selectedReport = type
                                showSheet = false
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                List {
                    let reports: [(date: Date, income: Double, expense: Double)] = getReports()
                    ForEach(reports, id: \.date) { report in
                        HStack {
                            Text(formatDate(report.date, for: selectedReport))
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            Text("Gelir: \(report.income, specifier: "%.2f")₺")
                                .foregroundColor(.green)
                            Spacer()
                            Text("Gider: \(report.expense, specifier: "%.2f")₺")
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Raporlar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func getReports() -> [(date: Date, income: Double, expense: Double)] {
        switch selectedReport {
        case .daily:
            return viewModel.dailyReport()
        case .monthly:
            return viewModel.monthlyReport()
        case .yearly:
            return viewModel.yearlyReport()
        }
    }
    
    private func formatDate(_ date: Date, for reportType: ReportType) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        
        switch reportType {
        case .daily:
            formatter.dateFormat = "dd.MM.yyyy"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
        case .yearly:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: date)
    }
}

#Preview {
    ReportsView(viewModel: TransactionViewModel())
}
