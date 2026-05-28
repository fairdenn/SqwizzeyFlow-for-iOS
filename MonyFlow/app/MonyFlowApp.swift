import SwiftUI
import SwiftData

@main
struct MonyFlowApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Card.self, Transaction.self, Category.self, Statement.self
            )
            
            // Дефолтные категории при первом запуске
            CategoryProvider.seedDefaultsIfNeeded(context: modelContainer.mainContext)
            
            // Создаём недостающие выписки для всех кредитных карт
            StatementGenerator.generateMissingStatements(
                context: modelContainer.mainContext
            )
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.locale, Locale(identifier: "ru_RU"))
                .onAppear {
                    StatementGenerator.generateMissingStatements(
                        context: modelContainer.mainContext
                    )
                }
        }
        .modelContainer(modelContainer)
    }
}
