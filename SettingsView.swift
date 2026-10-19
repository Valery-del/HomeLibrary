import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Отображение") {
                    Picker("Режим", selection: $settings.displayMode) {
                        ForEach(SettingsStore.DisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Сортировка") {
                    Picker("Сортировать", selection: $settings.sortOrder) {
                        ForEach(SettingsStore.SortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                }
                
                Section("Цель чтения") {
                    Stepper(value: $settings.yearlyReadingGoal, in: 1...200) {
                        Text("Книг в год: \(settings.yearlyReadingGoal)")
                    }
                }
            }
            .navigationTitle("Настройки")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
