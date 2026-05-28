import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Главная", systemImage: "chart.pie.fill") {
                DashboardView()
            }
            Tab("Карты", systemImage: "creditcard.fill") {
                CardsView()
            }
            Tab("Добавить", systemImage: "plus.circle.fill") {
                AddTransactionView()
            }
            Tab("Калькулятор", systemImage: "function") {
                CalculatorView()
            }
            Tab("Настройки", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    RootTabView()
}
