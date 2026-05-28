import Foundation
import SwiftData

enum TransactionKind: String, Codable {
    case expense
    case income
    case payment
    case transferOut
    case transferIn
}

@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var date: Date
    var kind: TransactionKind
    var note: String?
    var isCancelled: Bool          // флаг "отменена"
    var cancelledAt: Date?         // когда отменена
    
    var card: Card?
    var category: Category?
    
    var linkedTransaction: Transaction?
    
    init(
        amount: Decimal,
        date: Date = Date(),
        kind: TransactionKind,
        note: String? = nil,
        card: Card? = nil,
        category: Category? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.kind = kind
        self.note = note
        self.isCancelled = false
        self.cancelledAt = nil
        self.card = card
        self.category = category
    }
}
