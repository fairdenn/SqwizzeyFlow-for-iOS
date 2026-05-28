import Foundation

/// Уровень срочности выписки.
enum StatementUrgency {
    case overdue      // просрочена
    case burning      // горит: ≤ 3 дней
    case soon         // скоро: ≤ 7 дней
    case calm         // спокойно: > 7 дней
    case paid         // полностью оплачена
}

/// Расчёт производных значений по выписке: остаток к оплате, дни, срочность.
enum StatementCalculator {
    
    /// Сколько ещё надо внести по выписке (с учётом уже внесённого).
    static func remainingAmount(_ statement: Statement) -> Decimal {
        let remaining = statement.amountDue - statement.paidAmount
        return max(remaining, 0)
    }
    
    /// Сколько дней осталось до дедлайна.
    /// Отрицательное значение — просрочка.
    static func daysUntilDue(_ statement: Statement, today: Date = Date()) -> Int {
        DateHelper.daysBetween(today, statement.paymentDueDate)
    }
    
    /// Уровень срочности выписки.
    static func urgency(_ statement: Statement, today: Date = Date()) -> StatementUrgency {
        if remainingAmount(statement) <= 0 {
            return .paid
        }
        
        let days = daysUntilDue(statement, today: today)
        
        if days < 0 { return .overdue }
        if days <= 3 { return .burning }
        if days <= 7 { return .soon }
        return .calm
    }
    
    /// Доля выписки, которая уже оплачена (0.0 - 1.0).
    static func paidProgress(_ statement: Statement) -> Double {
        guard statement.amountDue > 0 else { return 0 }
        
        let paidDouble = NSDecimalNumber(decimal: statement.paidAmount).doubleValue
        let totalDouble = NSDecimalNumber(decimal: statement.amountDue).doubleValue
        return min(paidDouble / totalDouble, 1.0)
    }
    
    /// Считается ли выписка активной (есть остаток к оплате И не просрочена больше чем на 30 дней).
    /// Просроченные старее 30 дней считаем "ушедшими в проценты" — их не показываем как активные.
    static func isActive(_ statement: Statement, today: Date = Date()) -> Bool {
        guard remainingAmount(statement) > 0 else { return false }
        let days = daysUntilDue(statement, today: today)
        return days > -30
    }
}
