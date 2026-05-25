import SwiftUI
import Charts

struct AssetsChartView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(PriceStore.self) private var priceStore
    @EnvironmentObject private var investments: InvestmentStore

    private func quoteLookup(_ symbol: AssetSymbol) -> Quote? {
        priceStore.quote(for: symbol)
    }

    private var investmentValue: Double {
        investments.grandTotal(quoteLookup)
    }

    private var cashBalance: Double {
        viewModel.balance
    }

    private var totalAssets: Double {
        cashBalance + investmentValue
    }

    var body: some View {
        let series = viewModel.cumulativeBalanceMonthly(months: 6)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                StatMini(label: "Nakit", value: cashBalance, color: .neonBlue)
                StatMini(label: "Yatırım", value: investmentValue, color: .neonGreen)
                StatMini(label: "Toplam", value: totalAssets, color: .neonPurple)
            }
            .padding(.horizontal)

            Chart {
                ForEach(series, id: \.date) { point in
                    LineMark(
                        x: .value("Ay", point.date),
                        y: .value("Bakiye", point.balance)
                    )
                    .foregroundStyle(Color.neonBlue)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Ay", point.date),
                        y: .value("Bakiye", point.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.neonBlue.opacity(0.35), Color.neonBlue.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Ay", point.date),
                        y: .value("Bakiye", point.balance)
                    )
                    .foregroundStyle(Color.neonBlue)
                    .symbolSize(36)
                }

                if let last = series.last {
                    PointMark(
                        x: .value("Ay", last.date),
                        y: .value("Toplam", last.balance + investmentValue)
                    )
                    .foregroundStyle(Color.neonPurple)
                    .symbolSize(80)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Bugün")
                            .font(.caption2)
                            .foregroundColor(.neonPurple)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).locale(Locale(identifier: "tr_TR")))
                        .foregroundStyle(Color.gray)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
    }
}

private struct StatMini: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2).fontWeight(.semibold)
                .foregroundColor(.gray)
                .tracking(0.8)
            Text(formatTL(value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
    }

    private func formatTL(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.groupingSeparator = "."
        return "\(f.string(from: NSNumber(value: v)) ?? "\(Int(v))") TL"
    }
}
