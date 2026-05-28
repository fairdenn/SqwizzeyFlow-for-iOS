import Foundation
import SwiftData

/// Распределяет платёж между активными выписками карты.
/// Логика: гасим по очереди те выписки, у которых дедлайн ближе всего.
enum PaymentDistributor {
    
    /// Применяет платёж к выпискам карты. Возвращает массив затронутых выписок и сумму, ушедшую на каждую.
    @discardableResult
    static func applyPayment(
        amount: Decimal,
        toCard card: Card,
        context: ModelContext
    ) -> [(statement: Statement, applied: Decimal)] {
        guard amount > 0 else { return [] }
        
        // Активные выписки, отсортированные по дедлайну (горящие первые)
        let activeStatements = card.statements
            .filter { StatementCalculator.isActive($0) }
            .sorted { $0.paymentDueDate < $1.paymentDueDate }
        
        var remaining = amount
        var applied: [(statement: Statement, applied: Decimal)] = []
        
        for statement in activeStatements {
            guard remaining > 0 else { break }
            
            let stillOwed = StatementCalculator.remainingAmount(statement)
            guard stillOwed > 0 else { continue }
            
            // Закрываем эту выписку настолько, насколько хватит платежа
            let toApply = min(stillOwed, remaining)
            statement.paidAmount += toApply
            remaining -= toApply
            
            // Если выписка закрыта полностью — отмечаем как закрытую
            if StatementCalculator.remainingAmount(statement) <= 0 {
                statement.isClosed = true
            }
            
            applied.append((statement, toApply))
        }
        
        try? context.save()
        return applied
    }
    
    /// Откатывает платёж — например, при отмене транзакции погашения.
    /// Возвращает `paidAmount` выписок к состоянию "до платежа".
    static func revertPayment(
        amount: Decimal,
        fromCard card: Card,
        context: ModelContext
    ) {
        guard amount > 0 else { return }
        
        // Откатываем в обратном порядке: сначала те выписки, которые гасили последними
        // (по нашей логике — с самым дальним дедлайном из активных)
        let touchedStatements = card.statements
            .filter { $0.paidAmount > 0 }
            .sorted { $0.paymentDueDate > $1.paymentDueDate }
        
        var remaining = amount
        
        for statement in touchedStatements {
            guard remaining > 0 else { break }
            
            let canRevert = min(statement.paidAmount, remaining)
            statement.paidAmount -= canRevert
            remaining -= canRevert
            
            // Если откатили часть платежа — выписка снова не закрыта
            if statement.isClosed && StatementCalculator.remainingAmount(statement) > 0 {
                statement.isClosed = false
            }
        }
        
        try? context.save()
    }
}
