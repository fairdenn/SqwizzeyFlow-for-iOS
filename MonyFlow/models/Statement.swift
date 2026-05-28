import Foundation
import SwiftData

@Model
final class Statement {
    var id: UUID
    var card: Card?
    
    var periodStart: Date         // начало расчётного периода
    var periodEnd: Date           // дата закрытия выписки
    var paymentDueDate: Date      // дедлайн для сохранения грейса
    
    var amountDue: Decimal        // сколько надо внести
    var minimumPayment: Decimal   // минимальный платёж
    var paidAmount: Decimal       // уже внесено
    
    var isClosed: Bool            // выписка закрыта (грейс прошёл)
    
    init(
        card: Card? = nil,
        periodStart: Date,
        periodEnd: Date,
        paymentDueDate: Date,
        amountDue: Decimal,
        minimumPayment: Decimal = 0,
        paidAmount: Decimal = 0,
        isClosed: Bool = false
    ) {
        self.id = UUID()
        self.card = card
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.paymentDueDate = paymentDueDate
        self.amountDue = amountDue
        self.minimumPayment = minimumPayment
        self.paidAmount = paidAmount
        self.isClosed = isClosed
    }
}
