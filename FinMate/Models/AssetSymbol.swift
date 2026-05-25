import Foundation

enum AssetCategory: String, Codable, CaseIterable {
    case currency
    case turkishGold
    case ons
    case crypto

    var displayName: String {
        switch self {
        case .currency: return "Döviz"
        case .turkishGold: return "Altın"
        case .ons: return "Ons"
        case .crypto: return "Kripto"
        }
    }
}

enum AssetSymbol: String, Codable, CaseIterable, Identifiable, Hashable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"

    case gramAltin = "GRAM_ALTIN"
    case ceyrekAltin = "CEYREK_ALTIN"
    case yarimAltin = "YARIM_ALTIN"
    case tamAltin = "TAM_ALTIN"
    case cumhuriyetAltin = "CUMHURIYET_ALTIN"

    case onsAltin = "ONS_ALTIN"
    case onsGumus = "ONS_GUMUS"

    case btc = "BTC"
    case eth = "ETH"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .usd: return "Amerikan Doları"
        case .eur: return "Euro"
        case .gbp: return "İngiliz Sterlini"
        case .gramAltin: return "Gram Altın"
        case .ceyrekAltin: return "Çeyrek Altın"
        case .yarimAltin: return "Yarım Altın"
        case .tamAltin: return "Tam Altın"
        case .cumhuriyetAltin: return "Cumhuriyet Altını"
        case .onsAltin: return "Ons Altın"
        case .onsGumus: return "Ons Gümüş"
        case .btc: return "Bitcoin"
        case .eth: return "Ethereum"
        }
    }

    var shortCode: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "EUR"
        case .gbp: return "GBP"
        case .gramAltin: return "gr"
        case .ceyrekAltin: return "çeyrek"
        case .yarimAltin: return "yarım"
        case .tamAltin: return "tam"
        case .cumhuriyetAltin: return "cumhuriyet"
        case .onsAltin: return "oz Au"
        case .onsGumus: return "oz Ag"
        case .btc: return "BTC"
        case .eth: return "ETH"
        }
    }

    var category: AssetCategory {
        switch self {
        case .usd, .eur, .gbp: return .currency
        case .gramAltin, .ceyrekAltin, .yarimAltin, .tamAltin, .cumhuriyetAltin: return .turkishGold
        case .onsAltin, .onsGumus: return .ons
        case .btc, .eth: return .crypto
        }
    }

    var iconName: String {
        switch category {
        case .currency: return "dollarsign.circle.fill"
        case .turkishGold: return "circle.hexagongrid.fill"
        case .ons: return "scalemass.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        }
    }
}
