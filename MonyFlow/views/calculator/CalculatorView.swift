import SwiftUI
import SwiftData

struct CalculatorView: View {
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]
    
    @State private var viewModel = CalculatorViewModel()
    @State private var showAppliedToast = false
    
    var body: some View {
        NavigationStack {
            Group {
                if cards.filter({ $0.type == .debit }).isEmpty {
                    emptyDebitState
                } else if !hasActiveStatements {
                    emptyStatementsState
                } else {
                    mainContent
                }
            }
            .navigationTitle("Калькулятор")
        }
        .overlay(alignment: .top) {
            if showAppliedToast {
                appliedToast
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Пустые состояния
    
    private var emptyDebitState: some View {
        ContentUnavailableView {
            Label("Нет дебетовых карт", systemImage: "creditcard")
        } description: {
            Text("Добавьте дебетовую карту с балансом, чтобы калькулятор мог предложить варианты погашения.")
        }
    }
    
    private var emptyStatementsState: some View {
        ContentUnavailableView {
            Label("Нет активных выписок", systemImage: "checkmark.seal.fill")
        } description: {
            Text("Все кредитные карты сейчас закрыты или у вас нет долгов. Калькулятор не нужен — вы молодец!")
        }
    }
    
    // MARK: - Основной экран
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    inputCard
                    
                    if viewModel.hasResult {
                        resultBlock
                    }
                    
                    Spacer(minLength: 80)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.immediately)
            
            bottomBar
        }
        .background(AppColors.secondaryBackground)
        .onAppear { ensureSourceCard() }
    }
    
    // MARK: - Карточка ввода
    
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Сколько у вас денег для погашения?")
                .font(AppFonts.bodyBold)
            
            TextField("0 ₽", text: $viewModel.amountText)
                .keyboardType(.decimalPad)
                .font(AppFonts.moneyLarge)
                .padding(12)
                .background(AppColors.tertiaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            if debitCards.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Откуда")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.secondaryText)
                    
                    Picker("Откуда", selection: bindingForSource) {
                        ForEach(debitCards) { card in
                            Text(cardLabel(card)).tag(card.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let only = debitCards.first {
                HStack {
                    Text("Откуда")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.secondaryText)
                    Spacer()
                    Text(cardLabel(only))
                        .font(AppFonts.body)
                }
            }
            
            if let source = viewModel.sourceCard {
                HStack {
                    Text("Доступно на карте")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.secondaryText)
                    Spacer()
                    Text(source.balance.formattedRUB())
                        .font(AppFonts.moneySmall)
                }
            }
            
            if let message = viewModel.validationMessage {
                Text(message)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.debt)
            }
        }
        .padding(16)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Результат расчёта
    
    @ViewBuilder
    private var resultBlock: some View {
        if let result = viewModel.lastResult {
            VStack(alignment: .leading, spacing: 12) {
                summaryRow(result: result)
                
                Text("Рекомендованный план")
                    .font(AppFonts.bodyBold)
                    .padding(.top, 4)
                
                ForEach(result.suggestions) { suggestion in
                    SuggestionRowView(suggestion: suggestion)
                }
                
                if result.remaining > 0 {
                    remainingNote(result.remaining)
                }
            }
        }
    }
    
    private func summaryRow(result: SuggestionResult) -> some View {
        HStack(spacing: 12) {
            summaryItem(
                title: "Распределено",
                value: result.totalDistributed.formattedRUB(),
                color: AppColors.primary
            )
            summaryItem(
                title: "Закроет выписок",
                value: "\(result.coveredStatements)",
                color: AppColors.income
            )
        }
    }
    
    private func summaryItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.secondaryText)
            Text(value)
                .font(AppFonts.bodyBold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func remainingNote(_ remaining: Decimal) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppColors.warning)
            Text("Осталось \(remaining.formattedRUB()) — все активные выписки уже учтены.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Нижняя кнопка
    
    private var bottomBar: some View {
        VStack(spacing: 8) {
            if viewModel.hasResult {
                Button {
                    applySuggestions()
                } label: {
                    Text("Применить")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.income)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: AppColors.income.opacity(0.3), radius: 12, y: 4)
                }
                .padding(.horizontal, 16)
            } else {
                Button {
                    hideKeyboard()
                    viewModel.calculate(allCards: cards)
                } label: {
                    Text("Рассчитать")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.canCalculate ? AppColors.primary : AppColors.secondaryText.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: AppColors.primary.opacity(viewModel.canCalculate ? 0.3 : 0), radius: 12, y: 4)
                }
                .disabled(!viewModel.canCalculate)
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private var appliedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.income)
            Text("Платежи выполнены")
                .font(AppFonts.body)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.background)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
    
    // MARK: - Хелперы
    
    private var debitCards: [Card] {
        cards.filter { $0.type == .debit }
    }
    
    private var hasActiveStatements: Bool {
        cards
            .filter { $0.type == .credit }
            .flatMap { $0.statements }
            .contains { StatementCalculator.isActive($0) }
    }
    
    private var bindingForSource: Binding<UUID> {
        Binding(
            get: { viewModel.sourceCard?.id ?? debitCards.first?.id ?? UUID() },
            set: { id in
                viewModel.sourceCard = cards.first { $0.id == id }
                viewModel.reset()  // сбрасываем результат при смене карты
            }
        )
    }
    
    private func cardLabel(_ card: Card) -> String {
        if let last = card.lastFour, !last.isEmpty {
            return "\(card.name) •••• \(last)"
        }
        return card.name
    }
    
    private func ensureSourceCard() {
        if viewModel.sourceCard == nil || !debitCards.contains(where: { $0.id == viewModel.sourceCard?.id }) {
            viewModel.sourceCard = debitCards.first
        }
    }
    
    private func applySuggestions() {
        viewModel.apply(context: context)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showAppliedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showAppliedToast = false
            }
        }
    }
}

#Preview {
    CalculatorView()
        .modelContainer(for: Card.self, inMemory: true)
}
