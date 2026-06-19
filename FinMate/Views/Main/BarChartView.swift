
import SwiftUI
import Charts

public struct BarChartView: View {
    @ObservedObject var viewModel: TransactionViewModel
    var month: Date = Date()

    public var body: some View {
        let data = viewModel.dailyIncomeExpense(for: month)
        let maxDay = data.map { $0.day }.max() ?? 30
        let stride = chartStride(for: maxDay)
        let tickValues = Array(Swift.stride(from: 1, through: maxDay, by: stride))

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                LegendDot(color: .neonGreen, label: "Gelir")
                LegendDot(color: .neonRed, label: "Gider")
                Spacer()
                Text(monthName(month))
                    .font(.caption).foregroundColor(.gray)
            }
            .padding(.horizontal)

            Chart {
                ForEach(data, id: \.day) { item in
                    LineMark(
                        x: .value("Gün", item.day),
                        y: .value("Gelir", item.income),
                        series: .value("Tür", "Gelir")
                    )
                    .foregroundStyle(Color.neonGreen)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Gün", item.day),
                        y: .value("Gelir", item.income),
                        series: .value("Tür", "Gelir")
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.neonGreen.opacity(0.35), Color.neonGreen.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Gün", item.day),
                        y: .value("Gider", item.expense),
                        series: .value("Tür", "Gider")
                    )
                    .foregroundStyle(Color.neonRed)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Gün", item.day),
                        y: .value("Gider", item.expense),
                        series: .value("Tür", "Gider")
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.neonRed.opacity(0.30), Color.neonRed.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: tickValues) { value in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text("\(day)").foregroundColor(.gray).font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
            .frame(height: 220)
            .padding(.horizontal)
        }
    }

    private func chartStride(for maxDay: Int) -> Int {
        if maxDay <= 10 { return 1 }
        if maxDay <= 15 { return 2 }
        if maxDay <= 25 { return 4 }
        return 5
    }

    private func monthName(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date).capitalized
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.6), radius: 3)
            Text(label)
                .font(.caption).foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    ZStack {
        Color.midnightBackground.ignoresSafeArea()
        BarChartView(viewModel: TransactionViewModel())
    }
}
