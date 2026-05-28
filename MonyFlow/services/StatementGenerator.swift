import Foundation
import SwiftData

/// Автоматически создаёт выписки для кредитных карт.
/// Запускается при старте приложения и проверяет, нет ли пропущенных выписок.
enum StatementGenerator {
    
    /// Прогоняет всех кредитные карты и создаёт недостающие выписки до сегодняшнего дня.
    static func generateMissingStatements(context: ModelContext, today: Date = Date()) {
            // Берём все карты, потом фильтруем кредитные в памяти
            // (предикаты SwiftData плохо работают с enum.rawValue)
            let descriptor = FetchDescriptor<Card>()
            guard let allCards = try? context.fetch(descriptor) else { return }
            
            let creditCards = allCards.filter { $0.type == .credit }
            
            for card in creditCards {
                generateForCard(card, today: today, context: context)
            }
            
            try? context.save()
        }
    
    /// Создаёт недостающие выписки для одной конкретной карты.
    private static func generateForCard(_ card: Card, today: Date, context: ModelContext) {
        // Находим дату последней выписки по этой карте
        let lastStatementEnd = card.statements
            .map { $0.periodEnd }
            .max()
        
        // Определяем с какого месяца начинать генерацию
        let startFrom: Date
        if let lastEnd = lastStatementEnd {
            // Следующий период начинается сразу после конца предыдущего
            startFrom = DateHelper.adding(days: 1, to: lastEnd)
        } else {
            // Первый запуск для этой карты — начинаем с месяца создания карты
            startFrom = card.createdAt
        }
        
        // Генерируем выписки по одной, пока не догоним сегодняшний день
        var cursor = startFrom
        while shouldGenerateStatement(cursor: cursor, today: today, card: card) {
            let statement = buildStatement(for: card, cursorDate: cursor)
            context.insert(statement)
            
            // Сдвигаем курсор на следующий период
            cursor = DateHelper.adding(days: 1, to: statement.periodEnd)
        }
    }
    
    /// Проверяет, должна ли быть создана выписка для текущего курсора.
    /// Выписка создаётся, если день закрытия (statementDay) уже наступил или прошёл.
    private static func shouldGenerateStatement(cursor: Date, today: Date, card: Card) -> Bool {
        let (year, month) = DateHelper.yearMonth(cursor)
        let statementCloseDate = DateHelper.date(
            year: year,
            month: month,
            day: card.statementDay
        )
        
        // Если день закрытия в этом месяце ещё впереди — ждём
        if statementCloseDate >= cursor && statementCloseDate <= today {
            return true
        }
        
        // Если курсор уже после дня закрытия в этом месяце — смотрим следующий месяц
        if cursor > statementCloseDate {
            let nextMonth = DateHelper.adding(months: 1, to: cursor)
            let (nextYear, nextMonthNum) = DateHelper.yearMonth(nextMonth)
            let nextClose = DateHelper.date(
                year: nextYear,
                month: nextMonthNum,
                day: card.statementDay
            )
            return nextClose <= today
        }
        
        return false
    }
    
    /// Создаёт одну выписку для карты, исходя из позиции курсора.
    private static func buildStatement(for card: Card, cursorDate: Date) -> Statement {
        let (cursorYear, cursorMonth) = DateHelper.yearMonth(cursorDate)
        
        // Дата закрытия выписки
        var periodEnd = DateHelper.date(
            year: cursorYear,
            month: cursorMonth,
            day: card.statementDay
        )
        // Если день закрытия в этом месяце уже позади курсора — берём следующий месяц
        if periodEnd < cursorDate {
            let nextMonth = DateHelper.adding(months: 1, to: cursorDate)
            let (y, m) = DateHelper.yearMonth(nextMonth)
            periodEnd = DateHelper.date(year: y, month: m, day: card.statementDay)
        }
        periodEnd = DateHelper.endOfDay(periodEnd)
        
        // Начало периода — день после предыдущего закрытия (или 30 дней назад для первого)
        let periodStart = DateHelper.startOfDay(
            DateHelper.adding(days: -30, to: periodEnd)
        )
        
        // Дата дедлайна платежа — день платежа после закрытия
        let paymentDueDate = calculatePaymentDueDate(
            periodEnd: periodEnd,
            paymentDueDay: card.paymentDueDay
        )
        
        // Сумма выписки — все траты по этой карте в расчётном периоде
        let amountDue = sumExpenses(
            card: card,
            from: periodStart,
            to: periodEnd
        )
        
        return Statement(
            card: card,
            periodStart: periodStart,
            periodEnd: periodEnd,
            paymentDueDate: paymentDueDate,
            amountDue: amountDue,
            minimumPayment: max(amountDue * Decimal(0.05), 0),  // 5% от выписки как минимальный
            paidAmount: 0,
            isClosed: false
        )
    }
    
    /// Рассчитывает дату дедлайна платежа.
    /// Если paymentDueDay в том же месяце что и закрытие, но раньше — берём следующий месяц.
    private static func calculatePaymentDueDate(periodEnd: Date, paymentDueDay: Int) -> Date {
        let (year, month) = DateHelper.yearMonth(periodEnd)
        var dueDate = DateHelper.date(year: year, month: month, day: paymentDueDay)
        
        // Если день платежа уже прошёл в этом месяце — берём следующий
        if dueDate <= periodEnd {
            let nextMonth = DateHelper.adding(months: 1, to: periodEnd)
            let (y, m) = DateHelper.yearMonth(nextMonth)
            dueDate = DateHelper.date(year: y, month: m, day: paymentDueDay)
        }
        
        return DateHelper.endOfDay(dueDate)
    }
    
    /// Сумма расходов по карте в заданном периоде (без отменённых).
    private static func sumExpenses(card: Card, from: Date, to: Date) -> Decimal {
        let expenses = card.transactions.filter { transaction in
            transaction.kind == .expense &&
            !transaction.isCancelled &&
            transaction.date >= from &&
            transaction.date <= to
        }
        return expenses.reduce(Decimal(0)) { $0 + $1.amount }
    }
}
