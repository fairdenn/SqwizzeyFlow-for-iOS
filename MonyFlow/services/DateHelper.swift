import Foundation

/// Вспомогательные функции для работы с датами выписок.
enum DateHelper {
    
    private static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        return c
    }()
    
    /// Возвращает дату с указанным днём месяца в заданном месяце.
    /// Если день больше количества дней в месяце (например, 31 февраля) — берётся последний день месяца.
    static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let firstDay = calendar.date(from: components) else {
            return Date()
        }
        
        let range = calendar.range(of: .day, in: .month, for: firstDay) ?? 1..<29
        let safeDay = min(day, range.upperBound - 1)
        components.day = safeDay
        
        return calendar.date(from: components) ?? Date()
    }
    
    /// Начало дня (00:00:00).
    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    /// Конец дня (23:59:59).
    static func endOfDay(_ date: Date) -> Date {
        let start = startOfDay(date)
        return calendar.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1) ?? date
    }
    
    /// Возвращает дату, увеличенную на N дней.
    static func adding(days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
    
    /// Возвращает дату, увеличенную на N месяцев.
    static func adding(months: Int, to date: Date) -> Date {
        calendar.date(byAdding: .month, value: months, to: date) ?? date
    }
    
    /// Количество дней между двумя датами (по календарным суткам).
    /// Положительное — если to позже from.
    static func daysBetween(_ from: Date, _ to: Date) -> Int {
        let fromStart = startOfDay(from)
        let toStart = startOfDay(to)
        let components = calendar.dateComponents([.day], from: fromStart, to: toStart)
        return components.day ?? 0
    }
    
    /// Год и месяц для конкретной даты.
    static func yearMonth(_ date: Date) -> (year: Int, month: Int) {
        let components = calendar.dateComponents([.year, .month], from: date)
        return (components.year ?? 2024, components.month ?? 1)
    }
}
