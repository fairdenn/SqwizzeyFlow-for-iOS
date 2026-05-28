import SwiftUI

struct StatementCardView: View {
    let statement: Statement
    
    private var urgency: StatementUrgency {
        StatementCalculator.urgency(statement)
    }
    
    private var daysLeft: Int {
        StatementCalculator.daysUntilDue(statement)
    }
    
    private var remaining: Decimal {
        StatementCalculator.remainingAmount(statement)
    }
    
    private var progress: Double {
        StatementCalculator.paidProgress(statement)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            amountBlock
            progressBlock
            deadlineRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Заголовок
    
    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: urgencyIcon)
                    .foregroundStyle(urgencyAccent)
                Text(urgencyTitle)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(urgencyAccent)
            }
            Spacer()
            Text(periodText)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
    }
    
    // MARK: - Сумма
    
    private var amountBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("К оплате")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.secondaryText)
            Text(remaining.formattedRUB())
                .font(AppFonts.moneyLarge)
                .foregroundStyle(AppColors.primaryText)
            if statement.paidAmount > 0 {
                Text("Внесено: \(statement.paidAmount.formattedRUB()) из \(statement.amountDue.formattedRUB())")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }
    
    // MARK: - Прогресс
    
    @ViewBuilder
    private var progressBlock: some View {
        if statement.amountDue > 0 {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.tertiaryBackground)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(urgencyAccent)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - Строка дедлайна
    
    private var deadlineRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.secondaryText)
            Text(deadlineText)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            Text(daysLeftText)
                .font(AppFonts.caption)
                .fontWeight(.semibold)
                .foregroundStyle(urgencyAccent)
        }
    }
    
    // MARK: - Тексты
    
    private var urgencyTitle: String {
        switch urgency {
        case .overdue: return "Просрочено"
        case .burning: return "Срочно!"
        case .soon:    return "Скоро дедлайн"
        case .calm:    return "Активная выписка"
        case .paid:    return "Оплачено"
        }
    }
    
    private var urgencyIcon: String {
        switch urgency {
        case .overdue: return "exclamationmark.triangle.fill"
        case .burning: return "flame.fill"
        case .soon:    return "clock.fill"
        case .calm:    return "doc.text.fill"
        case .paid:    return "checkmark.seal.fill"
        }
    }
    
    private var periodText: String {
        let start = statement.periodStart.formatted(.dateTime.day().month().locale(Locale(identifier: "ru_RU")))
        let end = statement.periodEnd.formatted(.dateTime.day().month().locale(Locale(identifier: "ru_RU")))
        return "\(start) — \(end)"
    }
    
    private var deadlineText: String {
        let date = statement.paymentDueDate.formatted(.dateTime.day().month().year().locale(Locale(identifier: "ru_RU")))
        return "Внести до \(date)"
    }
    
    private var daysLeftText: String {
        switch urgency {
        case .paid:
            return "Выписка закрыта"
        case .overdue:
            return "Просрочено на \(abs(daysLeft)) дн."
        default:
            return daysWord(daysLeft)
        }
    }
    
    /// Правильно склоняет "день/дня/дней" по числу.
    private func daysWord(_ days: Int) -> String {
        let lastTwo = abs(days) % 100
        let last = abs(days) % 10
        let word: String
        if lastTwo >= 11 && lastTwo <= 14 {
            word = "дней"
        } else if last == 1 {
            word = "день"
        } else if (2...4).contains(last) {
            word = "дня"
        } else {
            word = "дней"
        }
        return "Осталось \(days) \(word)"
    }
    
    // MARK: - Цвета
    
    private var urgencyAccent: Color {
        switch urgency {
        case .overdue: return AppColors.debt
        case .burning: return AppColors.debt
        case .soon:    return AppColors.warning
        case .calm:    return AppColors.primary
        case .paid:    return AppColors.income
        }
    }
    
    private var backgroundColor: Color {
        AppColors.background
    }
    
    private var borderColor: Color {
        urgencyAccent.opacity(0.3)
    }
}
