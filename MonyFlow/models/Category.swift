import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String           // "Еда", "Транспорт"
    var sfSymbol: String       // "cart.fill", "fuelpump"
    var colorHex: String
    var monthlyBudget: Decimal?  // опционально — лимит на месяц
    
    @Relationship(inverse: \Transaction.category)
    var transactions: [Transaction] = []
    
    init(
        name: String,
        sfSymbol: String = "tag.fill",
        colorHex: String = "#888888",
        monthlyBudget: Decimal? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
        self.monthlyBudget = monthlyBudget
    }
}
