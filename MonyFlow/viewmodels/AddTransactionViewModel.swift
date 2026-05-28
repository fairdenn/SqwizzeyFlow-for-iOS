import Foundation
import SwiftData

@Observable
final class AddTransactionViewModel {
    var amountText: String = ""
    var kind: TransactionKind = .expense
    var date: Date = Date()
    var selectedCard: Card?           // основная карта (расход/доход) или кредитка для погашения
    var sourceCard: Card?             // дебетовая, ОТКУДА списываем при погашении
    var selectedCategory: Category?
    var note: String = ""
    
    // MARK: - Валидация
    
    var amount: Decimal {
        let normalized = amountText
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        return Decimal(string: normalized) ?? 0
    }
    
    var canSave: Bool {
        guard amount > 0 else { return false }
        guard selectedCard != nil else { return false }
        
        // Для погашения нужна вторая карта — источник
        if kind == .payment {
            guard let source = sourceCard else { return false }
            // И на дебетовке должно хватить денег
            guard source.balance >= amount else { return false }
        }
        
        return true
    }
    
    /// Категория обязательна только для расходов.
    var requiresCategory: Bool {
        kind == .expense
    }
    
    /// Ошибка валидации (показываем под кнопкой если есть).
    var validationMessage: String? {
        guard amount > 0 else { return nil }
        
        if kind == .payment, let source = sourceCard, source.balance < amount {
            return "На карте «\(source.name)» недостаточно средств. Доступно: \(source.balance.formattedRUB())."
        }
        return nil
    }
    
    // MARK: - Сохранение
    
    func save(context: ModelContext) {
        guard let card = selectedCard else { return }
        
        switch kind {
        case .payment:
            // Парная транзакция: с дебетовой на кредитную
            guard let source = sourceCard else { return }
            TransactionService.createPayment(
                amount: amount,
                date: date,
                fromDebit: source,
                toCredit: card,
                note: note.isEmpty ? nil : note.trimmingCharacters(in: .whitespaces),
                context: context
            )
            
        default:
            // Обычная одиночная транзакция
            TransactionService.create(
                amount: amount,
                kind: kind,
                date: date,
                card: card,
                category: kind == .expense ? selectedCategory : nil,
                note: note.isEmpty ? nil : note.trimmingCharacters(in: .whitespaces),
                context: context
            )
        }
    }
}
