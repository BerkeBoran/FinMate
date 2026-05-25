import Foundation
import Observation

@Observable
@MainActor
final class PriceStore {
    private(set) var quotes: [AssetSymbol: Quote] = [:]
    private(set) var lastRefresh: Date?
    private(set) var isLoading: Bool = false
    private(set) var lastError: String?

    private let provider: PriceProvider
    private let refreshInterval: TimeInterval
    private let staleThreshold: TimeInterval
    private var timerTask: Task<Void, Never>?

    init(
        provider: PriceProvider = CollectAPIProvider(),
        refreshInterval: TimeInterval = 15 * 60,
        staleThreshold: TimeInterval = 60
    ) {
        self.provider = provider
        self.refreshInterval = refreshInterval
        self.staleThreshold = staleThreshold
    }

    func start() {
        guard timerTask == nil else { return }
        Task { await refresh() }
        timerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.refreshInterval * 1_000_000_000))
                if Task.isCancelled { break }
                await self.refresh()
            }
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
    }

    func refreshIfStale() async {
        if let last = lastRefresh, Date.now.timeIntervalSince(last) < staleThreshold {
            return
        }
        await refresh()
    }

    func refresh() async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fresh = try await provider.fetchAll()
            quotes = normalize(fresh)
            lastRefresh = .now
            lastError = nil
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func quote(for symbol: AssetSymbol) -> Quote? {
        quotes[symbol]
    }

    // MARK: - Currency Conversion (used by Settings & main views)

    /// TL tutarını verilen para birimi sembolüne dönüştürür.
    /// Henüz kur yüklenmediyse veya sembol desteklenmiyorsa TL değerini olduğu gibi döner.
    func convertFromTRY(_ tlAmount: Double, toSymbol symbol: String) -> Double {
        guard symbol != "₺" else { return tlAmount }
        let asset: AssetSymbol?
        switch symbol {
        case "$": asset = .usd
        case "€": asset = .eur
        case "£": asset = .gbp
        default: asset = nil
        }
        guard let asset, let q = quotes[asset], q.buyTRY > 0 else { return tlAmount }
        return tlAmount / q.buyTRY
    }

    /// Kurların hazır olup olmadığını verir (en az USD/EUR/GBP'den birinin yüklenmiş olması).
    var hasRates: Bool {
        quotes[.usd] != nil || quotes[.eur] != nil || quotes[.gbp] != nil
    }

    // Kripto endpoint'i USD bazlı döner; USD/TRY ile çarpıp TRY'ye çevirir.
    private func normalize(_ raw: [Quote]) -> [AssetSymbol: Quote] {
        // CollectAPI bazı sembollerde birden fazla satır döndürüyor (örn. "Çeyrek Eski"/"Çeyrek Yeni"
        // ikisi de .ceyrekAltin'e map'leniyor). Çakışmada ilk değeri tutuyoruz.
        var map = Dictionary(raw.map { ($0.symbol, $0) }, uniquingKeysWith: { first, _ in first })
        if let usd = map[.usd] {
            for sym in [AssetSymbol.btc, .eth] {
                if let q = map[sym] {
                    map[sym] = Quote(
                        symbol: sym,
                        buyTRY: q.buyTRY * usd.buyTRY,
                        sellTRY: q.sellTRY * usd.sellTRY,
                        updatedAt: q.updatedAt
                    )
                }
            }
            if let ons = map[.onsAltin] {
                let buying = ons.buyTRY < 10_000 ? ons.buyTRY * usd.buyTRY : ons.buyTRY
                let selling = ons.sellTRY < 10_000 ? ons.sellTRY * usd.sellTRY : ons.sellTRY
                map[.onsAltin] = Quote(symbol: .onsAltin, buyTRY: buying, sellTRY: selling, updatedAt: ons.updatedAt)
            }
            if let ons = map[.onsGumus] {
                let buying = ons.buyTRY < 1_000 ? ons.buyTRY * usd.buyTRY : ons.buyTRY
                let selling = ons.sellTRY < 1_000 ? ons.sellTRY * usd.sellTRY : ons.sellTRY
                map[.onsGumus] = Quote(symbol: .onsGumus, buyTRY: buying, sellTRY: selling, updatedAt: ons.updatedAt)
            }
        }
        return map
    }
}
