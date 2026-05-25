import SwiftUI
import Charts

struct AssetsChartView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(PriceStore.self) private var priceStore
    @EnvironmentObject private var investments: InvestmentStore

    @AppStorage(SettingsKeys.hideBalance) private var hideBalance: Bool = false
    @AppStorage(SettingsKeys.currencySymbol) private var currencySymbol: String = "₺"
    @AppStorage(SettingsKeys.decimalPlaces) private var decimalPlaces: Int = 2

    private func quoteLookup(_ symbol: AssetSymbol) -> Quote? {
        priceStore.quote(for: symbol)
    }

    private var investmentValueTL: Double {
        investments.grandTotal(quoteLookup)
    }

    private var cashBalanceTL: Double {
        viewModel.balance
    }

    private var totalAssetsTL: Double {
        cashBalanceTL + investmentValueTL
    }

    private func display(_ tl: Double) -> Double {
        priceStore.convertFromTRY(tl, toSymbol: currencySymbol)
    }

    var body: some View {
        let series = viewModel.cumulativeBalanceMonthly(months: 6)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                StatMini(label: "Nakit", value: display(cashBalanceTL), symbol: currencySymbol, color: .neonBlue, hidden: hideBalance, decimals: decimalPlaces)
                StatMini(label: "Yatırım", value: display(investmentValueTL), symbol: currencySymbol, color: .neonGreen, hidden: hideBalance, decimals: decimalPlaces)
                StatMini(label: "Toplam", value: display(totalAssetsTL), symbol: currencySymbol, color: .neonPurple, hidden: hideBalance, decimals: decimalPlaces)
            }
            .padding(.horizontal)

            ZStack {
                Chart {
                    ForEach(series, id: \.date) { point in
                        let displayBalance = display(point.balance)
                        LineMark(
                            x: .value("Ay", point.date),
                            y: .value("Bakiye", displayBalance)
                        )
                        .foregroundStyle(Color.neonBlue)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        AreaMark(
                            x: .value("Ay", point.date),
                            y: .value("Bakiye", displayBalance)
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
                            y: .value("Bakiye", displayBalance)
                        )
                        .foregroundStyle(Color.neonBlue)
                        .symbolSize(36)
                    }

                    if let last = series.last {
                        PointMark(
                            x: .value("Ay", last.date),
                            y: .value("Toplam", display(last.balance + investmentValueTL))
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
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).locale(Locale(identifier: "tr_TR")))
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel().foregroundStyle(hideBalance ? .clear : Color.gray)
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
                .opacity(hideBalance ? 0.15 : 1.0)
                .blur(radius: hideBalance ? 8 : 0)

                if hideBalance {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(.gray)
                        Text("Bakiye Gizli")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.gray)
                    }
                }
            }
            .animation(.easeInOut, value: hideBalance)
        }
    }
}

private struct StatMini: View {
    let label: String
    let value: Double
    let symbol: String
    let color: Color
    let hidden: Bool
    let decimals: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2).fontWeight(.semibold)
                .foregroundColor(.gray)
                .tracking(0.8)
            Text(hidden ? "•••• \(symbol)" : formatted)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.opacity)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
        .animation(.easeInOut, value: hidden)
    }

    private var formatted: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = decimals
        f.minimumFractionDigits = 0
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        let numberPart = f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(numberPart) \(symbol)"
    }
}
