import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        Label("Категории", systemImage: "tag.fill")
                    }
                }
                
                Section {
                    HStack {
                        Label("Версия", systemImage: "info.circle")
                        Spacer()
                        Text("0.1.0 (MVP)")
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}

#Preview { SettingsView() }
