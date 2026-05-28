import Foundation
import SwiftData

@Observable
final class CalculatorViewModel {
    var amountText: String = "" {
        didSet {
            // Любое изменение суммы → старый план невалиден
            if amountText != oldValue {
                lastResult = nil
            }
        }
    }
    
    var sourceCard: Card? {
        didSet {
            // Смена источника → план тоже сбрасываем
            if sourceCard?.id != oldValue?.id {
                lastResult = nil
            }
        }
    }
    
    var lastResult: SuggestionResult?
    
    var amount: Decimal {
        let normalized = amountText
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        return Decimal(string: normalized) ?? 0
    }
    
    var canCalculate: Bool {
        amount > 0 && sourceCard != nil
    }
    
    var hasResult: Bool {
        guard let result = lastResult else { return false }
        return !result.suggestions.isEmpty
    }
    
    var validationMessage: String? {
        guard amount > 0, let source = sourceCard else { return nil }
        if source.balance < amount {
            return "На карте «\(source.name)» доступно только \(source.balance.formattedRUB())."
        }
        return nil
    }
    
    func calculate(allCards: [Card]) {
        guard let source = sourceCard else { return }
        
        let result = PaymentSuggester.suggest(
            amount: amount,
            from: source,
            allCards: allCards
        )
        lastResult = result
    }
    
    func apply(context: ModelContext) {
        guard let result = lastResult else { return }
        PaymentSuggester.applySuggestions(result.suggestions, context: context)
        
        amountText = ""
        lastResult = nil
    }
    
    func reset() {
        amountText = ""
        lastResult = nil
    }
}
