import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var viewModel = AddTransactionViewModel()
    @State private var showSavedToast = false
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    emptyState
                } else {
                    mainContent
                }
            }
            .navigationTitle("Добавить")
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("Нет карт", systemImage: "creditcard")
        } description: {
            Text("Сначала добавьте хотя бы одну карту во вкладке «Карты».")
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            Form {
                kindSection
                amountSection
                
                if viewModel.kind == .payment {
                    paymentCardsSection
                } else {
                    singleCardSection
                }
                
                if viewModel.requiresCategory {
                    categorySection
                }
                
                dateSection
                noteSection
            }
            .scrollDismissesKeyboard(.immediately)
            .onAppear { ensureDefaults() }
            .onChange(of: viewModel.kind) { _, _ in ensureDefaults() }
            .onChange(of: cards.count) { _, _ in ensureDefaults() }
            
            bottomBar
        }
        .overlay(alignment: .top) {
            if showSavedToast {
                savedToast
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Нижняя панель с кнопкой
    
    private var bottomBar: some View {
            VStack(spacing: 8) {
                if let message = viewModel.validationMessage {
                    Text(message)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.debt)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                Button {
                    hideKeyboard()
                    viewModel.save(context: context)
                    showSavedToastAndReset()
                } label: {
                    Text("Сохранить")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.canSave ? AppColors.primary : AppColors.secondaryText.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: AppColors.primary.opacity(viewModel.canSave ? 0.3 : 0), radius: 12, y: 4)
                }
                .disabled(!viewModel.canSave)
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    
    // MARK: - Секции формы
    
    private var kindSection: some View {
        Section("Тип операции") {
            Picker("Тип", selection: $viewModel.kind) {
                Text("Расход").tag(TransactionKind.expense)
                Text("Доход").tag(TransactionKind.income)
                Text("Погашение").tag(TransactionKind.payment)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var amountSection: some View {
        Section("Сумма") {
            TextField("0 ₽", text: $viewModel.amountText)
                .keyboardType(.decimalPad)
                .font(AppFonts.moneyMedium)
                .focused($isFieldFocused)
        }
    }
    
    /// Для расхода и дохода — одна карта.
    @ViewBuilder
    private var singleCardSection: some View {
        Section(cardSectionTitle) {
            if filteredCards.isEmpty {
                Text("Нет подходящих карт")
                    .foregroundStyle(AppColors.secondaryText)
            } else if filteredCards.count == 1 {
                // Единственная карта — показываем без пикера
                singleCardRow(filteredCards[0])
            } else {
                Picker("Карта", selection: bindingForSelectedCard) {
                    ForEach(filteredCards) { card in
                        Text(cardLabel(card)).tag(card.id)
                    }
                }
            }
        }
    }
    
    private func singleCardRow(_ card: Card) -> some View {
        HStack {
            Text("Карта")
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            Text(cardLabel(card))
                .foregroundStyle(AppColors.primaryText)
        }
    }
    
    /// Для погашения — две секции: откуда и куда.
    private var paymentCardsSection: some View {
        Group {
            Section("Откуда списываем") {
                if debitCards.isEmpty {
                    Text("Нет дебетовых карт")
                        .foregroundStyle(AppColors.debt)
                } else if debitCards.count == 1 {
                    singleCardRow(debitCards[0])
                    availableRow(for: debitCards[0])
                } else {
                    Picker("Дебетовая карта", selection: bindingForSourceCard) {
                        ForEach(debitCards) { card in
                            Text(debitLabel(card)).tag(card.id)
                        }
                    }
                    if let source = viewModel.sourceCard {
                        availableRow(for: source)
                    }
                }
            }
            
            Section("Какую кредитку гасим") {
                if creditCards.isEmpty {
                    Text("Нет кредитных карт")
                        .foregroundStyle(AppColors.debt)
                } else if creditCards.count == 1 {
                    singleCardRow(creditCards[0])
                    debtRow(for: creditCards[0])
                } else {
                    Picker("Кредитная карта", selection: bindingForSelectedCard) {
                        ForEach(creditCards) { card in
                            Text(creditLabel(card)).tag(card.id)
                        }
                    }
                    if let target = viewModel.selectedCard {
                        debtRow(for: target)
                    }
                }
            }
        }
    }
    
    private func availableRow(for card: Card) -> some View {
        HStack {
            Text("Доступно")
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            Text(card.balance.formattedRUB())
                .font(AppFonts.moneySmall)
        }
    }
    
    private func debtRow(for card: Card) -> some View {
        HStack {
            Text("Текущий долг")
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            Text(card.currentDebt.formattedRUB())
                .font(AppFonts.moneySmall)
                .foregroundStyle(AppColors.debt)
        }
    }
    
    private var categorySection: some View {
        Section("Категория") {
            Picker("Категория", selection: $viewModel.selectedCategory) {
                Text("Без категории").tag(Category?.none)
                ForEach(categories) { category in
                    HStack {
                        Image(systemName: category.sfSymbol)
                            .foregroundStyle(Color(hex: category.colorHex))
                        Text(category.name)
                    }
                    .tag(Category?.some(category))
                }
            }
        }
    }
    
    private var dateSection: some View {
        Section("Дата") {
            DatePicker("Когда", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
        }
    }
    
    private var noteSection: some View {
        Section("Заметка (необязательно)") {
            TextField("Например, продукты в Пятёрочке", text: $viewModel.note, axis: .vertical)
                .lineLimit(1...3)
                .focused($isFieldFocused)
        }
    }
    
    private var savedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.income)
            Text("Транзакция сохранена")
                .font(AppFonts.body)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.background)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
    
    // MARK: - Биндинги для пикеров (по UUID, чтобы не падать)
    
    /// Биндинг к выбранной карте по её UUID.
    private var bindingForSelectedCard: Binding<UUID> {
        Binding(
            get: { viewModel.selectedCard?.id ?? filteredCards.first?.id ?? UUID() },
            set: { id in
                viewModel.selectedCard = cards.first { $0.id == id }
            }
        )
    }
    
    private var bindingForSourceCard: Binding<UUID> {
        Binding(
            get: { viewModel.sourceCard?.id ?? debitCards.first?.id ?? UUID() },
            set: { id in
                viewModel.sourceCard = cards.first { $0.id == id }
            }
        )
    }
    
    // MARK: - Хелперы
    
    private var debitCards: [Card] {
        cards.filter { $0.type == .debit }
    }
    
    private var creditCards: [Card] {
        cards.filter { $0.type == .credit }
    }
    
    private var filteredCards: [Card] {
        switch viewModel.kind {
        case .income:
            return debitCards
        default:
            return cards
        }
    }
    
    private var cardSectionTitle: String {
        switch viewModel.kind {
        case .expense: return "С какой карты"
        case .income: return "Куда зачислить"
        default: return "Карта"
        }
    }
    
    private func cardLabel(_ card: Card) -> String {
        if let last = card.lastFour, !last.isEmpty {
            return "\(card.name) •••• \(last)"
        }
        return card.name
    }
    
    private func debitLabel(_ card: Card) -> String {
        cardLabel(card)
    }
    
    private func creditLabel(_ card: Card) -> String {
        let base = cardLabel(card)
        return "\(base) — \(card.currentDebt.formattedRUB())"
    }
    
    /// Гарантирует, что выбранные карты всегда соответствуют типу операции.
    /// Вызывается при появлении экрана, смене типа и появлении/исчезновении карт.
    private func ensureDefaults() {
        switch viewModel.kind {
        case .payment:
            // Источник: дебетовая
            if let current = viewModel.sourceCard, current.type == .debit, debitCards.contains(where: { $0.id == current.id }) {
                // ок
            } else {
                viewModel.sourceCard = debitCards.first
            }
            // Цель: кредитная
            if let current = viewModel.selectedCard, current.type == .credit, creditCards.contains(where: { $0.id == current.id }) {
                // ок
            } else {
                viewModel.selectedCard = creditCards.first
            }
        case .income:
            if let current = viewModel.selectedCard, current.type == .debit, debitCards.contains(where: { $0.id == current.id }) {
                // ок
            } else {
                viewModel.selectedCard = debitCards.first
            }
            viewModel.sourceCard = nil
        case .expense:
            if let current = viewModel.selectedCard, cards.contains(where: { $0.id == current.id }) {
                // ок
            } else {
                viewModel.selectedCard = cards.first
            }
            viewModel.sourceCard = nil
        default:
            viewModel.selectedCard = cards.first
            viewModel.sourceCard = nil
        }
    }
    
    private func showSavedToastAndReset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showSavedToast = true
        }
        
        let previousKind = viewModel.kind
        let previousCard = viewModel.selectedCard
        let previousSource = viewModel.sourceCard
        viewModel = AddTransactionViewModel()
        viewModel.kind = previousKind
        viewModel.selectedCard = previousCard
        viewModel.sourceCard = previousSource
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSavedToast = false
            }
        }
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: Card.self, inMemory: true)
}
