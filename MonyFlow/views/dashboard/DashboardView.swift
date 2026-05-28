import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Здесь будет сводка по картам и долгам")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding()
            }
            .navigationTitle("Главная")
        }
    }
}

#Preview { DashboardView() }
