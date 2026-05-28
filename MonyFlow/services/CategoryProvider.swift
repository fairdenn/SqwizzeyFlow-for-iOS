import Foundation
import SwiftData

/// Создаёт стандартный набор категорий при первом запуске приложения.
enum CategoryProvider {
    
    /// Стандартные категории — название, SF Symbol, цвет.
    static let defaults: [(name: String, symbol: String, color: String)] = [
        ("Продукты",      "cart.fill",                "#10B981"),
        ("Кафе и рестораны", "fork.knife",            "#F59E0B"),
        ("Транспорт",     "car.fill",                 "#3366D9"),
        ("АЗС",           "fuelpump.fill",            "#EF4444"),
        ("Жильё",         "house.fill",               "#A855F7"),
        ("Связь",         "antenna.radiowaves.left.and.right", "#0EA5E9"),
        ("Развлечения",   "gamecontroller.fill",      "#EC4899"),
        ("Одежда",        "tshirt.fill",              "#78716C"),
        ("Здоровье",      "cross.case.fill",          "#0F766E"),
        ("Образование",   "book.fill",                "#1F2937"),
        ("Подарки",       "gift.fill",                "#EC4899"),
        ("Подписки",      "rectangle.stack.fill",     "#A855F7"),
        ("Прочее",        "ellipsis.circle.fill",     "#78716C")
    ]
    
    /// Создаёт стандартные категории, если в базе ни одной нет.
    static func seedDefaultsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        
        for item in defaults {
            let category = Category(
                name: item.name,
                sfSymbol: item.symbol,
                colorHex: item.color
            )
            context.insert(category)
        }
        try? context.save()
    }
}
