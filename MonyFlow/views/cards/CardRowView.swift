import SwiftUI

struct CardRowView: View {
    let card: Card
    
    var body: some View {
        HStack(spacing: 16) {
            // Цветной квадрат с иконкой
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: card.colorHex))
                    .frame(width: 56, height: 40)
                
                Image(systemName: card.type == .credit ? "creditcard.fill" : "banknote.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.primaryText)
                
                HStack(spacing: 6) {
                    Text(card.bankName)
                    if let last = card.lastFour, !last.isEmpty {
                        Text("•••• \(last)")
                    }
                }
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amountText)
                    .font(AppFonts.moneySmall)
                    .foregroundStyle(amountColor)
                
                Text(card.type == .credit ? "Долг" : "Баланс")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var amountText: String {
        let value = card.type == .credit ? card.currentDebt : card.balance
        return value.formattedRUB()
    }
    
    private var amountColor: Color {
        if card.type == .credit {
            return card.currentDebt > 0 ? AppColors.debt : AppColors.primaryText
        }
        return AppColors.primaryText
    }
}
