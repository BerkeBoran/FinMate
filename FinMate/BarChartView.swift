//
//  BarChartView.swift
//  FinMate
//
//  Created by Berke Boran on 11.10.2025.
//

import SwiftUI
import Charts

public struct BarChartView: View {
    @ObservedObject var viewModel: TransactionViewModel
    var month: Date = Date()
    public var body: some View {
        VStack(alignment: .leading) {
            Text("Gelir - Gider Grafiği")
                .font(.headline)
                .padding(.horizontal)
            Chart {
                ForEach(viewModel.dailyBarChart(for: month), id: \.date) { item in
                    BarMark(
                        x: .value("Gün", formattedDaily(date: item.date)),
                        y: .value("Gelir", item.balance)
                    )
                    .foregroundStyle(item.balance >= 0 ? .green : .red)
                }
            }
            .frame(height: 250)
            .padding(.horizontal)
        }
    }
    
    func formattedDaily(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        return dateFormatter.string(from: date)
    }
}
    #Preview {
        BarChartView(viewModel: TransactionViewModel())
    }

