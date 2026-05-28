import SwiftUI
import SwiftData

struct AddCardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: AddCardViewModel
    
    init() {
        _viewModel = State(initialValue: AddCardViewModel(mode: .create))
    }
    
    init(editing card: Card) {
        _viewModel = State(initialValue: AddCardViewModel(mode: .edit(card)))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if viewModel.isTypeEditable {
                    typeSection
                }
                generalSection
                colorSection
                
                if viewModel.type == .debit {
                    debitSection
                } else {
                    creditSection
                    gracePeriodSection
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        viewModel.save(context: context)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                    .bold()
                }
            }
        }
    }
    
    private var typeSection: some View {
        Section("Тип карты") {
            Picker("Тип", selection: $viewModel.type) {
                Text("Дебетовая").tag(CardType.debit)
                Text("Кредитная").tag(CardType.credit)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var generalSection: some View {
        Section("Основное") {
            TextField("Название карты", text: $viewModel.name)
            TextField("Банк", text: $viewModel.bankName)
            TextField("Последние 4 цифры", text: $viewModel.lastFour)
                .keyboardType(.numberPad)
        }
    }
    
    private var colorSection: some View {
        Section("Цвет") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CardPalette.colors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(
                                        viewModel.selectedColor == hex
                                            ? AppColors.primaryText
                                            : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .onTapGesture {
                                viewModel.selectedColor = hex
                            }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var debitSection: some View {
        Section("Баланс") {
            TextField("Текущий баланс, ₽", text: $viewModel.balanceText)
                .keyboardType(.decimalPad)
        }
    }
    
    private var creditSection: some View {
        Section("Кредитный лимит") {
            TextField("Лимит, ₽", text: $viewModel.creditLimitText)
                .keyboardType(.decimalPad)
            TextField("Текущая задолженность, ₽", text: $viewModel.currentDebtText)
                .keyboardType(.decimalPad)
            TextField("Процентная ставка, %", text: $viewModel.interestRateText)
                .keyboardType(.decimalPad)
        }
    }
    
    private var gracePeriodSection: some View {
        Section("Грейс-период") {
            Stepper(
                "Длина грейса: \(viewModel.gracePeriodDays) дн.",
                value: $viewModel.gracePeriodDays,
                in: 1...365,
                step: 1
            )
            Stepper(
                "День закрытия выписки: \(viewModel.statementDay)",
                value: $viewModel.statementDay,
                in: 1...31,
                step: 1
            )
            Stepper(
                "День платежа: \(viewModel.paymentDueDay)",
                value: $viewModel.paymentDueDay,
                in: 1...31,
                step: 1
            )
        }
    }
}

#Preview("Создание") {
    AddCardView()
        .modelContainer(for: Card.self, inMemory: true)
}
