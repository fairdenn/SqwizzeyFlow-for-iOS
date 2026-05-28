import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedSymbol: String = "tag.fill"
    @State private var selectedColor: String = CardPalette.default
    
    private let symbols: [String] = [
        "tag.fill", "cart.fill", "fork.knife", "car.fill", "fuelpump.fill",
        "house.fill", "gamecontroller.fill", "tshirt.fill", "cross.case.fill",
        "book.fill", "gift.fill", "airplane", "pawprint.fill", "dumbbell.fill",
        "scissors", "wrench.and.screwdriver.fill", "creditcard.fill",
        "bag.fill", "cup.and.saucer.fill", "film.fill", "music.note",
        "ellipsis.circle.fill"
    ]
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например, Хобби", text: $name)
                }
                
                Section("Иконка") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(symbols, id: \.self) { symbol in
                            ZStack {
                                Circle()
                                    .fill(selectedSymbol == symbol
                                          ? Color(hex: selectedColor)
                                          : AppColors.tertiaryBackground)
                                    .frame(width: 44, height: 44)
                                Image(systemName: symbol)
                                    .foregroundStyle(selectedSymbol == symbol
                                                     ? .white
                                                     : AppColors.primaryText)
                            }
                            .onTapGesture {
                                selectedSymbol = symbol
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
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
                                                selectedColor == hex
                                                    ? AppColors.primaryText
                                                    : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .onTapGesture {
                                        selectedColor = hex
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Новая категория")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        save()
                        dismiss()
                    }
                    .disabled(!canSave)
                    .bold()
                }
            }
        }
    }
    
    private func save() {
        let category = Category(
            name: name.trimmingCharacters(in: .whitespaces),
            sfSymbol: selectedSymbol,
            colorHex: selectedColor
        )
        context.insert(category)
        try? context.save()
    }
}
