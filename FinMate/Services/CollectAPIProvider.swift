import Foundation

struct CollectAPIProvider: PriceProvider {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String = Config.collectAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    private static let base = URL(string: "https://api.collectapi.com")!

    func fetchAll() async throws -> [Quote] {
        guard Config.hasValidAPIKey else { throw PriceProviderError.missingAPIKey }

        async let currencies = fetchCurrencies()
        async let gold = fetchGold()
        async let crypto = fetchCrypto()

        let (cur, gld, cry) = try await (currencies, gold, crypto)
        return cur + gld + cry
    }

    // MARK: - Endpoints

    private func fetchCurrencies() async throws -> [Quote] {
        let url = Self.base.appending(path: "/economy/allCurrency")
        let response: CurrencyResponse = try await get(url)
        let now = Date.now
        return response.result.compactMap { row in
            guard let symbol = currencySymbol(for: row.code) else { return nil }
            return Quote(
                symbol: symbol,
                buyTRY: row.buying,
                sellTRY: row.selling,
                updatedAt: now
            )
        }
    }

    private func fetchGold() async throws -> [Quote] {
        let url = Self.base.appending(path: "/economy/goldPrice")
        let response: GoldResponse = try await get(url)
        let now = Date.now
        return response.result.compactMap { row in
            guard let symbol = goldSymbol(for: row.name) else { return nil }
            return Quote(
                symbol: symbol,
                buyTRY: row.buying,
                sellTRY: row.selling,
                updatedAt: now
            )
        }
    }

    private func fetchCrypto() async throws -> [Quote] {
        let url = Self.base.appending(path: "/economy/cripto")
        let response: CryptoResponse = try await get(url)
        let now = Date.now
        // CollectAPI kripto endpoint'i fiyatları USD bazında döner.
        // TL'ye çevirmek için USD/TRY kuruna ihtiyaç var; bunu PriceStore birleştirir.
        // Burada USD bazlı değeri buyTRY/sellTRY alanlarına aynı koyup PriceStore'da çeviriyoruz.
        return response.result.compactMap { row in
            guard let symbol = cryptoSymbol(for: row.code) else { return nil }
            let price = row.price
            return Quote(
                symbol: symbol,
                buyTRY: price,
                sellTRY: price,
                updatedAt: now
            )
        }
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("apikey \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw PriceProviderError.network(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw PriceProviderError.badResponse(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw PriceProviderError.decoding(error)
        }
    }

    // MARK: - Symbol mapping

    private func currencySymbol(for code: String) -> AssetSymbol? {
        switch code.uppercased() {
        case "USD": return .usd
        case "EUR": return .eur
        case "GBP": return .gbp
        default: return nil
        }
    }

    private func goldSymbol(for name: String) -> AssetSymbol? {
        let n = name.lowercased()
        if n.contains("gram") && !n.contains("gümüş") { return .gramAltin }
        if n.contains("çeyrek") { return .ceyrekAltin }
        if n.contains("yarım") { return .yarimAltin }
        if n.contains("tam") { return .tamAltin }
        if n.contains("cumhuriyet") { return .cumhuriyetAltin }
        if n.contains("ons") && n.contains("gümüş") { return .onsGumus }
        if n.contains("ons") { return .onsAltin }
        return nil
    }

    private func cryptoSymbol(for code: String) -> AssetSymbol? {
        switch code.uppercased() {
        case "BTC": return .btc
        case "ETH": return .eth
        default: return nil
        }
    }
}

// MARK: - DTOs

private struct CurrencyResponse: Decodable {
    let success: Bool
    let result: [Row]
    struct Row: Decodable {
        let code: String
        let buying: Double
        let selling: Double
    }
}

private struct GoldResponse: Decodable {
    let success: Bool
    let result: [Row]
    struct Row: Decodable {
        let name: String
        let buying: Double
        let selling: Double
    }
}

private struct CryptoResponse: Decodable {
    let success: Bool
    let result: [Row]
    struct Row: Decodable {
        let code: String
        let price: Double
    }
}
