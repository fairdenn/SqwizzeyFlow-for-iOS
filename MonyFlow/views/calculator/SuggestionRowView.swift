import SwiftUI

struct SuggestionRowView: View {
    let suggestion: PaymentSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Верх: причина + срочность
            HStack(spacing: 6) {
                Image(systemName: urgencyIcon)
                    .foregroundStyle(urgencyColor)
                    .font(.system(size: 13, weight: .semibold))
                Text(suggestion.reason.label)
                    .font(AppFonts.caption)
                    .foregroundStyle(urgencyColor)
                Spacer()
                if suggestion.coversFully {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.income)
                        Text("Закроет выписку")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.income)
                    }
                }
            }
            
            // Низ: визуальная стрелка от карты к карте
            HStack(spacing: 12) {
                cardChip(name: suggestion.fromCard.name, color: suggestion.fromCard.colorHex)
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(AppColors.secondaryText)
                
                cardChip(name: suggestion.toCard.name, color: suggestion.toCard.colorHex)
                
                Spacer()
                
                Text(suggestion.amount.formattedRUB())
                    .font(AppFonts.moneyMedium)
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .padding(14)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(urgencyColor.opacity(0.25), lineWidth: 1)
        )
    }
    
    private func cardChip(name: String, color: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 10, height: 10)
            Text(name)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
        }
    }
    
    private var urgencyIcon: String {
        switch suggestion.reason {
        case .overdue: return "exclamationmark.triangle.fill"
        case .burning: return "flame.fill"
        case .soon:    return "clock.fill"
        case .calm:    return "doc.text.fill"
        }
    }
    
    private var urgencyColor: Color {
        switch suggestion.reason {
        case .overdue: return AppColors.debt
        case .burning: return AppColors.debt
        case .soon:    return AppColors.warning
        case .calm:    return AppColors.primary
        }
    }
}
