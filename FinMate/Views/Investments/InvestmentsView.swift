import SwiftUI

class InvestmentStore: ObservableObject {
    @Published var currencyEntries: [CurrencyEntry] = [] {
        didSet { persist() }
    }
    @Published var metalEntries: [MetalEntry] = [] {
        didSet { persist() }
    }
    @Published var cryptoEntries: [CryptoEntry] = [] {
        didSet { persist() }
    }

    private let storageKey = "FinMate.investments.v1"
    private var isLoading = false

    init() {
        load()
    }

    private struct Snapshot: Codable {
        let currency: [CurrencyEntry]
        let metal: [MetalEntry]
        let crypto: [CryptoEntry]
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        currencyEntries = snap.currency
        metalEntries = snap.metal
        cryptoEntries = snap.crypto
    }

    private func persist() {
        guard !isLoading else { return }
        let snap = Snapshot(currency: currencyEntries, metal: metalEntries, crypto: cryptoEntries)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    typealias QuoteLookup = (AssetSymbol) -> Quote?

    var totalCostBasis: Double {
        currencyEntries.reduce(0) { $0 + $1.costTL } +
        metalEntries.reduce(0) { $0 + $1.costTL } +
        cryptoEntries.reduce(0) { $0 + $1.costTL }
    }

    func totalCurrencyValue(_ quoteFor: QuoteLookup) -> Double {
        currencyEntries.reduce(0) { $0 + $1.currentTL(quote: quoteFor($1.symbol)) }
    }

    func totalMetalValue(_ quoteFor: QuoteLookup) -> Double {
        metalEntries.reduce(0) { $0 + $1.currentTL(quote: quoteFor($1.symbol)) }
    }

    func totalCryptoValue(_ quoteFor: QuoteLookup) -> Double {
        cryptoEntries.reduce(0) { $0 + $1.currentTL(quote: quoteFor($1.symbol)) }
    }

    func grandTotal(_ quoteFor: QuoteLookup) -> Double {
        totalCurrencyValue(quoteFor) + totalMetalValue(quoteFor) + totalCryptoValue(quoteFor)
    }

    func allSlices(_ quoteFor: QuoteLookup) -> [PieSlice] {
        var result: [PieSlice] = []

        let groupedCurrency = Dictionary(grouping: currencyEntries, by: \.symbol)
        for (symbol, entries) in groupedCurrency.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let value = entries.reduce(0) { $0 + $1.currentTL(quote: quoteFor(symbol)) }
            result.append(PieSlice(label: symbol.shortCode, value: value, color: color(for: symbol)))
        }

        let groupedMetal = Dictionary(grouping: metalEntries, by: \.symbol)
        for (symbol, entries) in groupedMetal.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let value = entries.reduce(0) { $0 + $1.currentTL(quote: quoteFor(symbol)) }
            result.append(PieSlice(label: symbol.displayName, value: value, color: color(for: symbol)))
        }

        let groupedCrypto = Dictionary(grouping: cryptoEntries, by: \.symbol)
        for (symbol, entries) in groupedCrypto.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let value = entries.reduce(0) { $0 + $1.currentTL(quote: quoteFor(symbol)) }
            result.append(PieSlice(label: symbol.shortCode, value: value, color: color(for: symbol)))
        }

        return result.sorted { $0.value > $1.value }
    }

    func color(for symbol: AssetSymbol) -> Color {
        switch symbol {
        case .usd: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .eur: return Color(red: 0.2, green: 1.0, blue: 0.6)
        case .gbp: return Color(red: 0.8, green: 0.2, blue: 1.0)
        case .gramAltin: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .ceyrekAltin: return Color(red: 1.0, green: 0.72, blue: 0.0)
        case .yarimAltin: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .tamAltin: return Color(red: 1.0, green: 0.48, blue: 0.0)
        case .cumhuriyetAltin: return Color(red: 0.95, green: 0.55, blue: 0.1)
        case .onsAltin: return Color(red: 1.0, green: 0.9, blue: 0.4)
        case .onsGumus: return Color(red: 0.8, green: 0.8, blue: 0.85)
        case .btc: return Color(red: 0.96, green: 0.65, blue: 0.14)
        case .eth: return Color(red: 0.43, green: 0.5, blue: 0.95)
        }
    }
}

struct PieSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

struct DonutChartView: View {
    let slices: [PieSlice]
    let currentTotal: Double
    let costBasis: Double

    private var pnlDelta: Double { currentTotal - costBasis }
    private var pnlPercent: Double { costBasis > 0 ? (pnlDelta / costBasis) * 100 : 0 }
    private var pnlColor: Color {
        if pnlDelta > 0 { return Color(red: 0.2, green: 1.0, blue: 0.6) }
        if pnlDelta < 0 { return Color(red: 1.0, green: 0.35, blue: 0.4) }
        return Color.white.opacity(0.7)
    }

    private var angleSlices: [(slice: PieSlice, start: Double, end: Double)] {
        var result: [(PieSlice, Double, Double)] = []
        var cumulative = -Double.pi / 2
        for slice in slices {
            let sweep = (slice.value / currentTotal) * 2 * .pi
            result.append((slice, cumulative, cumulative + sweep))
            cumulative += sweep
        }
        return result
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                GeometryReader { geo in
                    let size   = min(geo.size.width, geo.size.height)
                    let cx     = geo.size.width  / 2
                    let cy     = geo.size.height / 2
                    let outer  = size / 2
                    let inner  = outer * 0.56

                    ZStack {
                        ForEach(0 ..< angleSlices.count, id: \.self) { i in
                            let s = angleSlices[i]
                            DonutSector(startAngle: s.start,
                                        endAngle:   s.end,
                                        innerRadius: inner,
                                        outerRadius: outer,
                                        center: CGPoint(x: cx, y: cy))
                                .fill(s.slice.color)
                                .shadow(color: s.slice.color.opacity(0.5), radius: 5)
                        }

                        Circle()
                            .fill(Color(red: 0.05, green: 0.07, blue: 0.12))
                            .frame(width: inner * 2, height: inner * 2)
                            .position(x: cx, y: cy)

                        VStack(spacing: 2) {
                            Text("GÜNCEL DEĞER")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color.gray)
                            Text(formatTL(currentTotal))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(width: inner * 1.6)
                        .position(x: cx, y: cy)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(height: 200)
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(slices) { slice in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(slice.color)
                            .shadow(color: slice.color.opacity(0.6), radius: 3)
                            .frame(width: 12, height: 12)
                        Text(slice.label)
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.85))
                        Spacer()
                        Text(String(format: "%.1f%%", slice.value / currentTotal * 100))
                            .font(.caption)
                            .foregroundColor(Color.gray)
                        Text(formatTL(slice.value))
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))
                            .frame(width: 90, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 4)

            Divider()
                .background(Color.white.opacity(0.15))

            VStack(spacing: 6) {
                HStack {
                    Text("Toplam Maliyet")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    Spacer()
                    Text(formatTL(costBasis))
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.8))
                }
                HStack {
                    Text("Güncel Değer")
                        .font(.headline)
                        .foregroundColor(Color.white)
                    Spacer()
                    Text(formatTL(currentTotal))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.2, green: 1.0, blue: 0.6))
                }
                HStack {
                    Text("Kâr / Zarar")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    Spacer()
                    Text(String(format: "%@ %@ (%+.2f%%)",
                                pnlDelta >= 0 ? "+" : "−",
                                formatTL(abs(pnlDelta)),
                                pnlPercent))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(pnlColor)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    func formatTL(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = "."
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(formatted) TL"
    }
}

struct DonutSector: Shape {
    let startAngle: Double
    let endAngle: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let center: CGPoint

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addArc(center: center, radius: outerRadius,
                     startAngle: .radians(startAngle),
                     endAngle:   .radians(endAngle), clockwise: false)
            p.addArc(center: center, radius: innerRadius,
                     startAngle: .radians(endAngle),
                     endAngle:   .radians(startAngle), clockwise: true)
            p.closeSubpath()
        }
    }
}

struct InvestmentsView: View {
    @EnvironmentObject private var store: InvestmentStore
    @Environment(PriceStore.self) private var priceStore

    private func quoteLookup(_ symbol: AssetSymbol) -> Quote? {
        priceStore.quote(for: symbol)
    }

    var body: some View {
        let grandTotal = store.grandTotal(quoteLookup)
        let slices = store.allSlices(quoteLookup)

        ScrollView {
            VStack(spacing: 20) {
                Text("Yatırımlarım")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)

                PriceStatusBar(priceStore: priceStore)
                    .padding(.horizontal)

                if !Config.hasValidAPIKey {
                    APIKeyMissingBanner()
                        .padding(.horizontal)
                }

                VStack(spacing: 15) {
                    NavigationLink(destination: CurrencyEntryView(store: store)) {
                        InvestmentMenuCard(icon: "dollarsign.circle.fill",
                                          title: "Döviz Girişi",
                                          subtitle: "Döviz yatırımlarını takip et",
                                          color: Color(red: 0.2, green: 0.6, blue: 1.0))
                    }
                    NavigationLink(destination: PreciousMetalsEntryView(store: store)) {
                        InvestmentMenuCard(icon: "circle.hexagongrid.fill",
                                          title: "Değerli Metal Girişi",
                                          subtitle: "Altın, gümüş",
                                          color: Color(red: 1.0, green: 0.84, blue: 0.0))
                    }
                    NavigationLink(destination: CryptoEntryView(store: store)) {
                        InvestmentMenuCard(icon: "bitcoinsign.circle.fill",
                                          title: "Kripto Girişi",
                                          subtitle: "Bitcoin, Ethereum",
                                          color: Color(red: 0.96, green: 0.65, blue: 0.14))
                    }
                }
                .padding(.horizontal)

                if grandTotal > 0 {
                    DonutChartView(slices: slices,
                                   currentTotal: grandTotal,
                                   costBasis: store.totalCostBasis)
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 48))
                            .foregroundColor(Color.white.opacity(0.15))
                        Text("Henüz yatırım girilmedi")
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(18)
                    .padding(.horizontal)
                }

                Spacer().frame(height: 30)
            }
            .padding(.vertical)
        }
        .midnightTheme()
        .navigationTitle("Yatırımlarım")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await priceStore.refreshIfStale()
        }
    }
}

struct PriceStatusBar: View {
    let priceStore: PriceStore

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(priceStore.isLoading ? Color.yellow : Color(red: 0.2, green: 1.0, blue: 0.6))
                .rotationEffect(.degrees(priceStore.isLoading ? 360 : 0))
                .animation(priceStore.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                           value: priceStore.isLoading)

            VStack(alignment: .leading, spacing: 2) {
                if let error = priceStore.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.4))
                        .lineLimit(2)
                } else if let last = priceStore.lastRefresh {
                    Text("Kurlar güncel — \(Self.timeFormatter.string(from: last))")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                } else {
                    Text("Kurlar yükleniyor…")
                        .font(.caption)
                        .foregroundColor(Color.gray)
                }
            }

            Spacer()

            Button {
                Task { await priceStore.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(priceStore.isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct APIKeyMissingBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("API anahtarı eksik")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(Color.white)
                Text("Anlık kurlar çekilemiyor. Config.swift dosyasına CollectAPI anahtarınızı girin.")
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct InvestmentMenuCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.7), radius: 8)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(Color.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CurrencyEntryView: View {
    @ObservedObject var store: InvestmentStore
    @Environment(PriceStore.self) private var priceStore
    @State private var selectedSymbol: AssetSymbol = .usd
    @State private var amount = ""
    @State private var buyRate = ""

    let currencies: [AssetSymbol] = [.usd, .eur, .gbp]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Yeni Döviz Ekle")
                        .font(.headline)
                        .foregroundColor(Color.white)

                    Picker("Döviz", selection: $selectedSymbol) {
                        ForEach(currencies) { Text($0.shortCode).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    if let q = priceStore.quote(for: selectedSymbol) {
                        HStack(spacing: 4) {
                            Text("Güncel kur:")
                                .font(.caption).foregroundColor(Color.gray)
                            Text(String(format: "%.2f TL", q.midTRY))
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.2, green: 1.0, blue: 0.6))
                            Spacer()
                        }
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Miktar")
                                .font(.caption).foregroundColor(Color.gray)
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .foregroundColor(Color.white)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Alış Kuru (TL)")
                                .font(.caption).foregroundColor(Color.gray)
                            TextField("0.00", text: $buyRate)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .foregroundColor(Color.white)
                        }
                    }

                    Button(action: addEntry) {
                        Text("Ekle")
                            .frame(maxWidth: .infinity)
                            .neonButton(color: Color(red: 0.2, green: 0.6, blue: 1.0))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)

                if !store.currencyEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Döviz Portföyüm")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(.horizontal)

                        ForEach(store.currencyEntries) { entry in
                            EntryRow(symbolLabel: entry.symbol.shortCode,
                                     symbolColor: store.color(for: entry.symbol),
                                     quantity: entry.amount,
                                     quantitySuffix: entry.symbol.shortCode,
                                     buyUnit: entry.buyRate,
                                     buyUnitLabel: "Alış",
                                     costTL: entry.costTL,
                                     currentTL: entry.currentTL(quote: priceStore.quote(for: entry.symbol)),
                                     pnl: entry.pnl(quote: priceStore.quote(for: entry.symbol)))
                                .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .midnightTheme()
        .navigationTitle("Döviz Girişi")
        .navigationBarTitleDisplayMode(.inline)
    }

    func addEntry() {
        guard let amt  = Double(amount.replacingOccurrences(of: ",", with: ".")),
              let rate = Double(buyRate.replacingOccurrences(of: ",", with: ".")) else { return }
        store.currencyEntries.append(CurrencyEntry(symbol: selectedSymbol, amount: amt, buyRate: rate))
        amount  = ""
        buyRate = ""
    }
}

struct EntryRow: View {
    let symbolLabel: String
    let symbolColor: Color
    let quantity: Double
    let quantitySuffix: String
    let buyUnit: Double
    let buyUnitLabel: String
    let costTL: Double
    let currentTL: Double
    let pnl: (delta: Double, percent: Double)

    private var pnlColor: Color {
        if pnl.delta > 0 { return Color(red: 0.2, green: 1.0, blue: 0.6) }
        if pnl.delta < 0 { return Color(red: 1.0, green: 0.35, blue: 0.4) }
        return Color.white.opacity(0.7)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(symbolLabel)
                        .font(.headline)
                        .foregroundColor(symbolColor)
                    Text(String(format: "%.2f %@", quantity, quantitySuffix))
                        .font(.caption).foregroundColor(Color.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTL(currentTL))
                        .font(.headline).foregroundColor(Color.white)
                    Text(String(format: "%@: %.2f TL", buyUnitLabel, buyUnit))
                        .font(.caption).foregroundColor(Color.gray)
                }
            }

            Divider().background(Color.white.opacity(0.08))

            HStack {
                Text("Maliyet: \(formatTL(costTL))")
                    .font(.caption2).foregroundColor(Color.white.opacity(0.6))
                Spacer()
                Text(String(format: "%@ %@ (%+.2f%%)",
                            pnl.delta >= 0 ? "+" : "−",
                            formatTL(abs(pnl.delta)),
                            pnl.percent))
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(pnlColor)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func formatTL(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.groupingSeparator = "."
        return "\(f.string(from: NSNumber(value: value)) ?? "\(Int(value))") TL"
    }
}

struct PreciousMetalsEntryView: View {
    @ObservedObject var store: InvestmentStore
    @Environment(PriceStore.self) private var priceStore
    @State private var selectedSymbol: AssetSymbol = .gramAltin
    @State private var quantity      = ""
    @State private var buyPrice      = ""

    let metals: [AssetSymbol] = [.gramAltin, .ceyrekAltin, .yarimAltin, .tamAltin, .cumhuriyetAltin, .onsAltin, .onsGumus]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Yeni Metal Ekle")
                        .font(.headline)
                        .foregroundColor(Color.white)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Metal / Birim")
                            .font(.caption).foregroundColor(Color.gray)
                        Picker("Metal", selection: $selectedSymbol) {
                            ForEach(metals) { Text($0.displayName).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .foregroundColor(Color.white)
                    }

                    if let q = priceStore.quote(for: selectedSymbol) {
                        HStack(spacing: 4) {
                            Text("Güncel fiyat:")
                                .font(.caption).foregroundColor(Color.gray)
                            Text(String(format: "%.2f TL", q.midTRY))
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            Spacer()
                        }
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Miktar")
                                .font(.caption).foregroundColor(Color.gray)
                            TextField("0.00", text: $quantity)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .foregroundColor(Color.white)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Alış Fiyatı (TL)")
                                .font(.caption).foregroundColor(Color.gray)
                            TextField("0.00", text: $buyPrice)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .foregroundColor(Color.white)
                        }
                    }

                    Button(action: addEntry) {
                        Text("Ekle")
                            .frame(maxWidth: .infinity)
                            .neonButton(color: Color(red: 1.0, green: 0.84, blue: 0.0))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)

                if !store.metalEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Metal Portföyüm")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(.horizontal)

                        ForEach(store.metalEntries) { entry in
                            EntryRow(symbolLabel: entry.symbol.displayName,
                                     symbolColor: store.color(for: entry.symbol),
                                     quantity: entry.quantity,
                                     quantitySuffix: entry.symbol.shortCode,
                                     buyUnit: entry.buyPrice,
                                     buyUnitLabel: "Birim Alış",
                                     costTL: entry.costTL,
                                     currentTL: entry.currentTL(quote: priceStore.quote(for: entry.symbol)),
                                     pnl: entry.pnl(quote: priceStore.quote(for: entry.symbol)))
                                .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .midnightTheme()
        .navigationTitle("Değerli Metal Girişi")
        .navigationBarTitleDisplayMode(.inline)
    }

    func addEntry() {
        guard let qty   = Double(quantity.replacingOccurrences(of: ",", with: ".")),
              let price = Double(buyPrice.replacingOccurrences(of: ",", with: ".")) else { return }
        store.metalEntries.append(MetalEntry(symbol: selectedSymbol, quantity: qty, buyPrice: price))
        quantity = ""
        buyPrice = ""
    }
}

struct CryptoEntryView: View {
    @ObservedObject var store: InvestmentStore
    @Environment(PriceStore.self) private var priceStore
    @State private var selectedSymbol: AssetSymbol = .btc
    @State private var amount = ""
    @State private var buyPrice = ""

    let cryptos: [AssetSymbol] = [.btc, .eth]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Yeni Kripto Ekle")
                        .font(.headline)
                        .foregroundColor(Color.white)

                    Picker("Kripto", selection: $selectedSymbol) {
                        ForEach(cryptos) { Text($0.shortCode).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    if let q = priceStore.quote(for: selectedSymbol) {
                        HStack(spacing: 4) {
                            Text("Güncel fiyat:")
                                .font(.caption).foregroundColor(Color.gray)
                            Text(String(format: "%.2f TL", q.midTRY))
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.96, green: 0.65, blue: 0.14))
                            Spacer()
                        }
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Miktar")
                                .font(.caption).foregroundColor(Color.gray)
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .foregroundColor(Color.white)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Alış Fiyatı (TL)")
                                .font(.caption).foregroundColor(Color.gray)
                            TextField("0.00", text: $buyPrice)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(10)
                                .foregroundColor(Color.white)
                        }
                    }

                    Button(action: addEntry) {
                        Text("Ekle")
                            .frame(maxWidth: .infinity)
                            .neonButton(color: Color(red: 0.96, green: 0.65, blue: 0.14))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)

                if !store.cryptoEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Kripto Portföyüm")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(.horizontal)

                        ForEach(store.cryptoEntries) { entry in
                            EntryRow(symbolLabel: entry.symbol.displayName,
                                     symbolColor: store.color(for: entry.symbol),
                                     quantity: entry.amount,
                                     quantitySuffix: entry.symbol.shortCode,
                                     buyUnit: entry.buyPrice,
                                     buyUnitLabel: "Birim Alış",
                                     costTL: entry.costTL,
                                     currentTL: entry.currentTL(quote: priceStore.quote(for: entry.symbol)),
                                     pnl: entry.pnl(quote: priceStore.quote(for: entry.symbol)))
                                .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .midnightTheme()
        .navigationTitle("Kripto Girişi")
        .navigationBarTitleDisplayMode(.inline)
    }

    func addEntry() {
        guard let amt   = Double(amount.replacingOccurrences(of: ",", with: ".")),
              let price = Double(buyPrice.replacingOccurrences(of: ",", with: ".")) else { return }
        store.cryptoEntries.append(CryptoEntry(symbol: selectedSymbol, amount: amt, buyPrice: price))
        amount = ""
        buyPrice = ""
    }
}

struct CurrencyEntry: Identifiable, Codable {
    let id = UUID()
    let symbol: AssetSymbol
    let amount: Double
    let buyRate: Double

    enum CodingKeys: String, CodingKey { case symbol, amount, buyRate }

    var costTL: Double { amount * buyRate }

    func currentTL(quote: Quote?) -> Double {
        guard let q = quote else { return costTL }
        return amount * q.midTRY
    }

    func pnl(quote: Quote?) -> (delta: Double, percent: Double) {
        let current = currentTL(quote: quote)
        let delta = current - costTL
        let percent = costTL > 0 ? (delta / costTL) * 100 : 0
        return (delta, percent)
    }
}

struct MetalEntry: Identifiable, Codable {
    let id = UUID()
    let symbol: AssetSymbol
    let quantity: Double
    let buyPrice: Double

    enum CodingKeys: String, CodingKey { case symbol, quantity, buyPrice }

    var costTL: Double { quantity * buyPrice }

    func currentTL(quote: Quote?) -> Double {
        guard let q = quote else { return costTL }
        return quantity * q.midTRY
    }

    func pnl(quote: Quote?) -> (delta: Double, percent: Double) {
        let current = currentTL(quote: quote)
        let delta = current - costTL
        let percent = costTL > 0 ? (delta / costTL) * 100 : 0
        return (delta, percent)
    }
}

struct CryptoEntry: Identifiable, Codable {
    let id = UUID()
    let symbol: AssetSymbol
    let amount: Double
    let buyPrice: Double

    enum CodingKeys: String, CodingKey { case symbol, amount, buyPrice }

    var costTL: Double { amount * buyPrice }

    func currentTL(quote: Quote?) -> Double {
        guard let q = quote else { return costTL }
        return amount * q.midTRY
    }

    func pnl(quote: Quote?) -> (delta: Double, percent: Double) {
        let current = currentTL(quote: quote)
        let delta = current - costTL
        let percent = costTL > 0 ? (delta / costTL) * 100 : 0
        return (delta, percent)
    }
}
