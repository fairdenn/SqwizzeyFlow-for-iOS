import Foundation
import SwiftData

enum CardType: String, Codable {
    case debit   // дебетовая
    case credit  // кредитная
}

@Model
final class Card {
    // Идентификатор
    var id: UUID
    var name: String          // "Тинькофф Платинум"
    var bankName: String      // "Тинькофф"
    var lastFour: String?     // последние 4 цифры (опционально)
    var colorHex: String      // цвет карточки в UI
    var type: CardType
    var createdAt: Date
    
    // --- Для дебетовых карт ---
    var balance: Decimal      // текущий баланс
    
    // --- Для кредитных карт ---
    var creditLimit: Decimal      // кредитный лимит
    var currentDebt: Decimal      // текущая задолженность
    var statementDay: Int         // день закрытия выписки (1-31)
    var paymentDueDay: Int        // день платежа (1-31)
    var gracePeriodDays: Int      // длина грейса (например, 55 или 100)
    var interestRate: Decimal     // % годовых после грейса
    
    // --- Связи ---
    @Relationship(deleteRule: .cascade, inverse: \Transaction.card)
    var transactions: [Transaction] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Statement.card)
    var statements: [Statement] = []
    
    init(
        name: String,
        bankName: String,
        lastFour: String? = nil,
        colorHex: String = "#3366D9",
        type: CardType,
        balance: Decimal = 0,
        creditLimit: Decimal = 0,
        currentDebt: Decimal = 0,
        statementDay: Int = 1,
        paymentDueDay: Int = 25,
        gracePeriodDays: Int = 55,
        interestRate: Decimal = 0
    ) {
        self.id = UUID()
        self.name = name
        self.bankName = bankName
        self.lastFour = lastFour
        self.colorHex = colorHex
        self.type = type
        self.createdAt = Date()
        self.balance = balance
        self.creditLimit = creditLimit
        self.currentDebt = currentDebt
        self.statementDay = statementDay
        self.paymentDueDay = paymentDueDay
        self.gracePeriodDays = gracePeriodDays
        self.interestRate = interestRate
    }
}
