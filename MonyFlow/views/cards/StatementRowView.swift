import SwiftUI

struct StatementRowView: View {
    let statement: Statement
    
    private var urgency: StatementUrgency {
        StatementCalculator.urgency(statement)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            
            VStack(alignment: .leading, spacing: 2) {
                Text(periodText)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.primaryText)
                
                Text(statusText)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(statement.amountDue.formattedRUB())
                    .font(AppFonts.moneySmall)
                    .foregroundStyle(AppColors.primaryText)
                
                Text(statement.paymentDueDate.formatted(.dateTime.day().month().locale(Locale(identifier: "ru_RU"))))
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(urgencyColor)
                .frame(width: 36, height: 36)
            Image(systemName: urgencyIcon)
                .foregroundStyle(.white)
                .font(.system(size: 14, weight: .semibold))
        }
    }
    
    private var urgencyIcon: String {
        switch urgency {
        case .paid:    return "checkmark"
        case .overdue: return "exclamationmark"
        case .burning: return "flame"
        case .soon:    return "clock"
        case .calm:    return "doc.text"
        }
    }
    
    private var urgencyColor: Color {
        switch urgency {
        case .paid:    return AppColors.income
        case .overdue: return AppColors.debt
        case .burning: return AppColors.debt
        case .soon:    return AppColors.warning
        case .calm:    return AppColors.primary
        }
    }
    
    private var periodText: String {
        let start = statement.periodStart.formatted(.dateTime.day().month().locale(Locale(identifier: "ru_RU")))
        let end = statement.periodEnd.formatted(.dateTime.day().month().locale(Locale(identifier: "ru_RU")))
        return "\(start) — \(end)"
    }
    
    private var statusText: String {
        switch urgency {
        case .paid:    return "Оплачено"
        case .overdue: return "Просрочено"
        case .burning: return "Срочно — горит"
        case .soon:    return "Скоро дедлайн"
        case .calm:    return "Активная"
        }
    }
}
