import Foundation

struct Quote: Equatable, Hashable {
    let symbol: AssetSymbol
    let buyTRY: Double
    let sellTRY: Double
    let updatedAt: Date

    var midTRY: Double {
        (buyTRY + sellTRY) / 2
    }
}
