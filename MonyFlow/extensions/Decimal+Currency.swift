import Foundation

extension Decimal {
    /// "12 345,50 ₽" — стандартный формат с копейками.
    func formattedRUB() -> String {
        self.formatted(
            .currency(code: "RUB")
                .locale(Locale(identifier: "ru_RU"))
        )
    }
    
    /// "12 346 ₽" — округлённый, для крупных сумм на дашборде.
    func formattedRUBRounded() -> String {
        self.formatted(
            .currency(code: "RUB")
                .locale(Locale(identifier: "ru_RU"))
                .precision(.fractionLength(0))
        )
    }
}
