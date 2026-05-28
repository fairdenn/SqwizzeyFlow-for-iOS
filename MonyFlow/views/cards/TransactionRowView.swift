import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body)
                    .foregroundStyle(titleColor)
                    .strikethrough(transaction.isCancelled, color: AppColors.secondaryText)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(AppFonts.moneySmall)
                    .foregroundStyle(amountColor)
                    .strikethrough(transaction.isCancelled, color: AppColors.secondaryText)
                
                Text(dateText)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.vertical, 4)
        .opacity(transaction.isCancelled ? 0.6 : 1.0)
    }
    
    // MARK: - Иконка
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconBackground)
                .frame(width: 36, height: 36)
            Image(systemName: iconSymbol)
                .foregroundStyle(.white)
                .font(.system(size: 14, weight: .semibold))
        }
    }
    
    private var iconSymbol: String {
        if transaction.isCancelled {
            return "arrow.uturn.backward"
        }
        if let category = transaction.category {
            return category.sfSymbol
        }
        switch transaction.kind {
        case .expense:     return "arrow.up.right"
        case .income:      return "arrow.down.left"
        case .payment:     return "arrow.down.left"
        case .transferOut: return "arrow.left.arrow.right"
        case .transferIn:  return "arrow.left.arrow.right"
        }
    }
    
    private var iconBackground: Color {
        if transaction.isCancelled {
            return AppColors.secondaryText
        }
        if let category = transaction.category {
            return Color(hex: category.colorHex)
        }
        switch transaction.kind {
        case .expense:     return AppColors.debt
        case .income:      return AppColors.income
        case .payment:     return AppColors.income
        case .transferOut: return AppColors.secondaryText
        case .transferIn:  return AppColors.secondaryText
        }
    }
    
    // MARK: - Текст
    
    private var title: String {
        if let note = transaction.note, !note.isEmpty {
            return note
        }
        if let category = transaction.category {
            return category.name
        }
        switch transaction.kind {
        case .expense:     return "Расход"
        case .income:      return "Пополнение"
        case .payment:     return "Погашение долга"
        case .transferOut: return "Перевод"
        case .transferIn:  return "Перевод"
        }
    }
    
    private var titleColor: Color {
        transaction.isCancelled ? AppColors.secondaryText : AppColors.primaryText
    }
    
    private var subtitle: String {
        if transaction.isCancelled {
            return "Отменена"
        }
        switch transaction.kind {
        case .expense:     return "Расход"
        case .income:      return "Пополнение"
        case .payment:     return "Погашение"
        case .transferOut: return "Списание на погашение"
        case .transferIn:  return "Зачисление"
        }
    }
    
    private var dateText: String {
        if transaction.isCancelled, let cancelledAt = transaction.cancelledAt {
            return "отм. " + cancelledAt.formatted(date: .abbreviated, time: .omitted)
        }
        return transaction.date.formatted(date: .abbreviated, time: .omitted)
    }
    
    // MARK: - Сумма
    
    private var amountText: String {
        let sign = isNegative ? "-" : "+"
        return "\(sign) \(transaction.amount.formattedRUB())"
    }
    
    private var amountColor: Color {
        if transaction.isCancelled {
            return AppColors.secondaryText
        }
        if isNegative {
            return AppColors.primaryText
        }
        return AppColors.income
    }
    
    private var isNegative: Bool {
        guard let card = transaction.card else { return false }
        
        switch transaction.kind {
        case .expense:
            return card.type == .debit
        case .income:
            return false
        case .payment:
            return card.type == .debit
        case .transferOut:
            return true
        case .transferIn:
            return false
        }
    }
}
