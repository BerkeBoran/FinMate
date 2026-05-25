import Foundation
import SwiftData

@Model
final class Holding {
    var symbolRaw: String
    var amount: Double
    var addedAt: Date

    init(symbol: AssetSymbol, amount: Double, addedAt: Date = .now) {
        self.symbolRaw = symbol.rawValue
        self.amount = amount
        self.addedAt = addedAt
    }

    var symbol: AssetSymbol {
        AssetSymbol(rawValue: symbolRaw) ?? .usd
    }
}
