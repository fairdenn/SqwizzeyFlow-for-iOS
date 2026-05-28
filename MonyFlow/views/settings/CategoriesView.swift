import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var showAddCategory = false
    
    var body: some View {
        List {
            ForEach(categories) { category in
                CategoryRow(category: category)
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("Категории")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView()
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            context.delete(categories[index])
        }
        try? context.save()
    }
}

private struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 36, height: 36)
                Image(systemName: category.sfSymbol)
                    .foregroundStyle(.white)
                    .font(.system(size: 15))
            }
            Text(category.name)
                .font(AppFonts.body)
        }
        .padding(.vertical, 2)
    }
}
