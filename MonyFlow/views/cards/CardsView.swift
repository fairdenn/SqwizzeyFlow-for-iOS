import SwiftUI
import SwiftData

struct CardsView: View {
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]
    
    @State private var showAddCard = false
    
    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(cards) { card in
                            NavigationLink {
                                CardDetailView(card: card)
                            } label: {
                                CardRowView(card: card)
                            }
                        }
                        .onDelete(perform: deleteCards)
                    }
                }
            }
            .navigationTitle("Карты")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCard = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCard) {
                AddCardView()
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("Нет карт", systemImage: "creditcard")
        } description: {
            Text("Добавьте свою первую карту, чтобы начать вести учёт.")
        } actions: {
            Button("Добавить карту") {
                showAddCard = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            context.delete(cards[index])
        }
        try? context.save()
    }
}

#Preview {
    CardsView()
        .modelContainer(for: Card.self, inMemory: true)
}
