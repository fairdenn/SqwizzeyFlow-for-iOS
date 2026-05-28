import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let card: Card
    
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                
                if card.type == .credit, let active = activeStatement {
                    StatementCardView(statement: active)
                }
                
                infoSection
                
                if card.type == .credit {
                    creditDetailsSection
                }
                
                if card.type == .credit, !pastStatements.isEmpty {
                    statementsHistorySection
                }
                
                transactionsSection
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(AppColors.secondaryBackground)
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Удалить карту", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddCardView(editing: card)
        }
        .confirmationDialog(
            "Удалить карту?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) {
                deleteCard()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Все транзакции по этой карте также будут удалены.")
        }
    }
    
    // MARK: - Большая карточка сверху
    
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(card.bankName)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: card.type == .credit ? "creditcard.fill" : "banknote.fill")
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(amountLabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text(amountValue)
                    .font(AppFonts.moneyLarge)
                    .foregroundStyle(.white)
            }
            
            if let last = card.lastFour, !last.isEmpty {
                Text("•••• \(last)")
                    .font(AppFonts.body)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: card.colorHex),
                    Color(hex: card.colorHex).opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Базовая инфа
    
    private var infoSection: some View {
        VStack(spacing: 0) {
            infoRow(title: "Тип", value: card.type == .credit ? "Кредитная" : "Дебетовая")
            Divider().padding(.leading)
            infoRow(title: "Банк", value: card.bankName)
            
            if let last = card.lastFour, !last.isEmpty {
                Divider().padding(.leading)
                infoRow(title: "Последние цифры", value: "•••• \(last)")
            }
        }
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Кредитные детали
    
    private var creditDetailsSection: some View {
        VStack(spacing: 0) {
            infoRow(title: "Лимит", value: card.creditLimit.formattedRUB())
            Divider().padding(.leading)
            infoRow(title: "Задолженность", value: card.currentDebt.formattedRUB())
            Divider().padding(.leading)
            infoRow(title: "Доступно", value: (card.creditLimit - card.currentDebt).formattedRUB())
            Divider().padding(.leading)
            infoRow(title: "Грейс-период", value: "\(card.gracePeriodDays) дней")
            Divider().padding(.leading)
            infoRow(title: "День выписки", value: "\(card.statementDay) число")
            Divider().padding(.leading)
            infoRow(title: "День платежа", value: "\(card.paymentDueDay) число")
            
            if card.interestRate > 0 {
                Divider().padding(.leading)
                infoRow(title: "Процентная ставка", value: "\(card.interestRate)%")
            }
        }
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - История выписок
    
    private var statementsHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("История выписок")
                    .font(AppFonts.bodyBold)
                Spacer()
                Text("\(pastStatements.count)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(pastStatements.enumerated()), id: \.element.id) { index, statement in
                    StatementRowView(statement: statement)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    if index < pastStatements.count - 1 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Транзакции
    
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("История операций")
                    .font(AppFonts.bodyBold)
                Spacer()
                Text("\(sortedTransactions.count)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.horizontal, 4)
            
            if sortedTransactions.isEmpty {
                emptyTransactions
            } else {
                transactionsList
            }
        }
    }
    
    private var emptyTransactions: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(AppColors.secondaryText)
            Text("Пока нет операций")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.secondaryText)
            Text("Смахните операцию влево, чтобы отменить")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var transactionsList: some View {
        List {
            ForEach(sortedTransactions) { transaction in
                TransactionRowView(transaction: transaction)
                    .listRowBackground(AppColors.background)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if transaction.isCancelled {
                            Button {
                                restoreTransaction(transaction)
                            } label: {
                                Label("Восстановить", systemImage: "arrow.uturn.backward")
                            }
                            .tint(AppColors.income)
                            
                            Button(role: .destructive) {
                                deleteForever(transaction)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        } else {
                            Button {
                                cancelTransaction(transaction)
                            } label: {
                                Label("Отменить", systemImage: "arrow.uturn.backward")
                            }
                            .tint(AppColors.warning)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .frame(height: listHeight)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var listHeight: CGFloat {
        let rowHeight: CGFloat = 60
        return CGFloat(sortedTransactions.count) * rowHeight
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            Text(value)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Вычисляемые свойства
    
    private var sortedTransactions: [Transaction] {
        card.transactions.sorted { $0.date > $1.date }
    }
    
    /// Текущая активная выписка — с остатком к оплате и не сильно просроченная.
    private var activeStatement: Statement? {
        card.statements
            .filter { StatementCalculator.isActive($0) }
            .sorted { $0.paymentDueDate < $1.paymentDueDate }
            .first
    }
    
    /// Прошлые выписки (закрытые/оплаченные/совсем просроченные).
    private var pastStatements: [Statement] {
        let activeID = activeStatement?.id
        return card.statements
            .filter { $0.id != activeID }
            .sorted { $0.periodEnd > $1.periodEnd }
    }
    
    private var amountLabel: String {
        card.type == .credit ? "Задолженность" : "Баланс"
    }
    
    private var amountValue: String {
        let value = card.type == .credit ? card.currentDebt : card.balance
        return value.formattedRUB()
    }
    
    // MARK: - Действия
    
    private func deleteCard() {
        context.delete(card)
        try? context.save()
        dismiss()
    }
    
    private func cancelTransaction(_ transaction: Transaction) {
        TransactionService.cancel(transaction, context: context)
    }
    
    private func restoreTransaction(_ transaction: Transaction) {
        TransactionService.restore(transaction, context: context)
    }
    
    private func deleteForever(_ transaction: Transaction) {
        TransactionService.deleteForever(transaction, context: context)
    }
}
