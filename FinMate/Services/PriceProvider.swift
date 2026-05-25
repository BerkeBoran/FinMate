import Foundation

protocol PriceProvider: Sendable {
    func fetchAll() async throws -> [Quote]
}

enum PriceProviderError: LocalizedError {
    case missingAPIKey
    case badResponse(Int)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API anahtarı eksik. Config.swift dosyasına CollectAPI anahtarınızı girin."
        case .badResponse(let code):
            return "Sunucu hatası (HTTP \(code))."
        case .decoding(let error):
            return "Veri çözümlenemedi: \(error.localizedDescription)"
        case .network(let error):
            return "Bağlantı hatası: \(error.localizedDescription)"
        }
    }
}
