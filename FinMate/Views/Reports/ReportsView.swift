
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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.midnightBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Raporlar")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showSheet.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.neonPurple.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .neonPurple.opacity(0.5), radius: 10)
                    }
                }
                .padding()
                
                VStack(spacing: 20) {
                    HStack {
                        Text("Görüntülenen: ")
                            .foregroundColor(.gray)
                        Text(selectedReport.rawValue)
                            .bold()
                            .foregroundColor(.neonBlue)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            let reports: [(date: Date, income: Double, expense: Double)] = getReports()
                            
                            if reports.isEmpty {
                                Text("Henüz veri yok.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 50)
                            } else {
                                ForEach(reports, id: \.date) { report in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(formatDate(report.date, for: selectedReport))
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(getDayName(date: report.date))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 5) {
                                            HStack {
                                                Image(systemName: "arrow.down.left")
                                                    .font(.caption2)
                                                Text("\(report.income, specifier: "%.2f")₺")
                                            }
                                            .foregroundColor(.neonGreen)
                                            .font(.subheadline)
                                            .bold()
                                            
                                            HStack {
                                                Image(systemName: "arrow.up.right")
                                                    .font(.caption2)
                                                Text("\(report.expense, specifier: "%.2f")₺")
                                            }
                                            .foregroundColor(.neonRed)
                                            .font(.subheadline)
                                            .bold()
                                        }
                                    }
                                    .padding()
                                    .glassCard()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSheet) {
            ZStack {
                Color.midnightBackground.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Text("Rapor Tipi Seçin")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    ForEach(ReportType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedReport = type
                            showSheet = false
                        }) {
                            Text(type.rawValue)
                                .font(.headline)
                                .foregroundColor(selectedReport == type ? .black : .white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedReport == type ? Color.neonBlue : Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
            }
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
            formatter.dateFormat = "dd MMMM yyyy"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
        case .yearly:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    private func getDayName(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

#Preview {
    ReportsView(viewModel: TransactionViewModel())
}
