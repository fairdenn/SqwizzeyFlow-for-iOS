import Foundation
import SwiftData

/// Одна рекомендация по платежу — "переведи X с дебетовки А на кредитку Б".
struct PaymentSuggestion: Identifiable {
    let id = UUID()
    let fromCard: Card           // дебетовая (источник)
    let toCard: Card             // кредитная (цель)
    let amount: Decimal          // сумма перевода
    let statement: Statement     // выписка, которую закрываем
    let reason: SuggestionReason // почему так советуем
    let coversFully: Bool        // полностью ли закроет выписку
}

/// Причина рекомендации — используется для текста в UI.
enum SuggestionReason {
    case overdue(daysLate: Int)
    case burning(daysLeft: Int)
    case soon(daysLeft: Int)
    case calm(daysLeft: Int)
    
    var label: String {
        switch self {
        case .overdue(let days): return "Просрочено на \(days) дн."
        case .burning(let days): return "Горит — \(days) дн. до дедлайна"
        case .soon(let days):    return "Скоро — \(days) дн."
        case .calm(let days):    return "Спокойно — \(days) дн."
        }
    }
    
    var priority: Int {
        switch self {
        case .overdue: return 0
        case .burning: return 1
        case .soon:    return 2
        case .calm:    return 3
        }
    }
}

/// Результат расчёта — список рекомендаций + сколько денег осталось.
struct SuggestionResult {
    let suggestions: [PaymentSuggestion]
    let totalDistributed: Decimal     // всего распределено
    let remaining: Decimal            // осталось нераспределённого
    let coveredStatements: Int        // сколько выписок полностью закроется
}

/// Умный распределитель платежей по выпискам кредитных карт.
enum PaymentSuggester {
    
    /// Главный метод: получив сумму и карту-источник, выдаёт оптимальный план погашений.
    /// - Parameters:
    ///   - amount: сколько денег у пользователя есть на погашение
    ///   - sourceCard: с какой дебетовой карты будем платить
    ///   - allCards: все карты (для поиска кредиток с активными выписками)
    static func suggest(
        amount: Decimal,
        from sourceCard: Card,
        allCards: [Card]
    ) -> SuggestionResult {
        guard amount > 0 else {
            return SuggestionResult(suggestions: [], totalDistributed: 0, remaining: 0, coveredStatements: 0)
        }
        
        // 1. Собираем все активные выписки со всех кредитных карт
        let creditCards = allCards.filter { $0.type == .credit }
        let activeStatements = creditCards.flatMap { card -> [Statement] in
            card.statements.filter { StatementCalculator.isActive($0) }
        }
        
        // 2. Сортируем по приоритету: просроченные → горящие → скоро → спокойные.
        // При равном приоритете — большая сумма к оплате идёт первой.
        let ranked = activeStatements
            .map { statement -> (Statement, SuggestionReason) in
                (statement, reasonFor(statement))
            }
            .sorted { lhs, rhs in
                if lhs.1.priority != rhs.1.priority {
                    return lhs.1.priority < rhs.1.priority
                }
                return StatementCalculator.remainingAmount(lhs.0) > StatementCalculator.remainingAmount(rhs.0)
            }
        
        // 3. Жадное распределение: закрываем выписки по очереди, пока есть деньги.
        var remaining = min(amount, sourceCard.balance)
        var suggestions: [PaymentSuggestion] = []
        var coveredCount = 0
        
        for (statement, reason) in ranked {
            guard remaining > 0 else { break }
            guard let toCard = statement.card else { continue }
            
            let needed = StatementCalculator.remainingAmount(statement)
            guard needed > 0 else { continue }
            
            let toPay = min(needed, remaining)
            let coversFully = toPay >= needed
            
            suggestions.append(PaymentSuggestion(
                fromCard: sourceCard,
                toCard: toCard,
                amount: toPay,
                statement: statement,
                reason: reason,
                coversFully: coversFully
            ))
            
            remaining -= toPay
            if coversFully {
                coveredCount += 1
            }
        }
        
        return SuggestionResult(
            suggestions: suggestions,
            totalDistributed: amount - remaining,
            remaining: remaining,
            coveredStatements: coveredCount
        )
    }
    
    /// Преобразует уровень срочности выписки в `SuggestionReason` с числовыми деталями.
    private static func reasonFor(_ statement: Statement) -> SuggestionReason {
        let days = StatementCalculator.daysUntilDue(statement)
        let urgency = StatementCalculator.urgency(statement)
        
        switch urgency {
        case .overdue: return .overdue(daysLate: abs(days))
        case .burning: return .burning(daysLeft: days)
        case .soon:    return .soon(daysLeft: days)
        case .calm:    return .calm(daysLeft: days)
        case .paid:    return .calm(daysLeft: days)  // не должно случиться, но на всякий
        }
    }
    
    /// Применяет рекомендации — создаёт все транзакции погашения.
    static func applySuggestions(
        _ suggestions: [PaymentSuggestion],
        context: ModelContext
    ) {
        for suggestion in suggestions {
            TransactionService.createPayment(
                amount: suggestion.amount,
                date: Date(),
                fromDebit: suggestion.fromCard,
                toCredit: suggestion.toCard,
                note: nil,
                context: context
            )
        }
    }
}
