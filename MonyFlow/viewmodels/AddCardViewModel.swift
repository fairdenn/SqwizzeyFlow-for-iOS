import Foundation
import SwiftData

@Observable
final class AddCardViewModel {
    enum Mode {
        case create
        case edit(Card)
    }
    
    let mode: Mode
    
    var name: String = ""
    var bankName: String = ""
    var lastFour: String = ""
    var selectedColor: String = CardPalette.default
    var type: CardType = .debit
    
    var balanceText: String = ""
    
    var creditLimitText: String = ""
    var currentDebtText: String = ""
    var statementDay: Int = 1
    var paymentDueDay: Int = 25
    var gracePeriodDays: Int = 55
    var interestRateText: String = ""
    
    init(mode: Mode = .create) {
        self.mode = mode
        
        if case .edit(let card) = mode {
            name = card.name
            bankName = card.bankName
            lastFour = card.lastFour ?? ""
            selectedColor = card.colorHex
            type = card.type
            balanceText = formatForEdit(card.balance)
            creditLimitText = formatForEdit(card.creditLimit)
            currentDebtText = formatForEdit(card.currentDebt)
            statementDay = card.statementDay
            paymentDueDay = card.paymentDueDay
            gracePeriodDays = card.gracePeriodDays
            interestRateText = formatForEdit(card.interestRate)
        }
    }
    
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !bankName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var navigationTitle: String {
        switch mode {
        case .create: return "Новая карта"
        case .edit:   return "Редактировать"
        }
    }
    
    var isTypeEditable: Bool {
        if case .create = mode { return true }
        return false
    }
    
    func save(context: ModelContext) {
        switch mode {
        case .create:
            createCard(in: context)
        case .edit(let card):
            updateCard(card, in: context)
        }
    }
    
    private func createCard(in context: ModelContext) {
        let card = Card(
            name: name.trimmingCharacters(in: .whitespaces),
            bankName: bankName.trimmingCharacters(in: .whitespaces),
            lastFour: lastFour.isEmpty ? nil : lastFour,
            colorHex: selectedColor,
            type: type,
            balance: type == .debit ? parseDecimal(balanceText) : 0,
            creditLimit: type == .credit ? parseDecimal(creditLimitText) : 0,
            currentDebt: type == .credit ? parseDecimal(currentDebtText) : 0,
            statementDay: statementDay,
            paymentDueDay: paymentDueDay,
            gracePeriodDays: gracePeriodDays,
            interestRate: type == .credit ? parseDecimal(interestRateText) : 0
        )
        context.insert(card)
        try? context.save()
    }
    
    private func updateCard(_ card: Card, in context: ModelContext) {
        card.name = name.trimmingCharacters(in: .whitespaces)
        card.bankName = bankName.trimmingCharacters(in: .whitespaces)
        card.lastFour = lastFour.isEmpty ? nil : lastFour
        card.colorHex = selectedColor
        
        if card.type == .debit {
            card.balance = parseDecimal(balanceText)
        } else {
            card.creditLimit = parseDecimal(creditLimitText)
            card.currentDebt = parseDecimal(currentDebtText)
            card.statementDay = statementDay
            card.paymentDueDay = paymentDueDay
            card.gracePeriodDays = gracePeriodDays
            card.interestRate = parseDecimal(interestRateText)
        }
        
        try? context.save()
    }
    
    private func parseDecimal(_ text: String) -> Decimal {
        let normalized = text
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        return Decimal(string: normalized) ?? 0
    }
    
    private func formatForEdit(_ value: Decimal) -> String {
        guard value != 0 else { return "" }
        return "\(value)"
    }
}
