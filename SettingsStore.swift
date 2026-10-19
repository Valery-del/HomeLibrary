import Foundation
import Observation

@Observable
final class SettingsStore {
    private let defaults = UserDefaults.standard
    
    var sortOrder: SortOrder {
        didSet {
            defaults.set(sortOrder.rawValue, forKey: "sortOrder")
        }
    }
    
    var displayMode: DisplayMode {
        didSet {
            defaults.set(displayMode.rawValue, forKey: "displayMode")
        }
    }
    
    var yearlyReadingGoal: Int {
        didSet {
            defaults.set(yearlyReadingGoal, forKey: "yearlyGoal")
        }
    }
    
    init() {
        // Загружаем сохранённые значения
        let savedSort = defaults.string(forKey: "sortOrder") ?? "dateAdded"
        self.sortOrder = SortOrder(rawValue: savedSort) ?? .dateAdded
        
        let savedMode = defaults.string(forKey: "displayMode") ?? "grid"
        self.displayMode = DisplayMode(rawValue: savedMode) ?? .grid
        
        let savedGoal = defaults.integer(forKey: "yearlyGoal")
        self.yearlyReadingGoal = savedGoal == 0 ? 20 : savedGoal
    }
    
    enum SortOrder: String, CaseIterable, Identifiable {
        case title = "По названию"
        case author = "По автору"
        case year = "По году"
        case rating = "По оценке"
        case dateAdded = "По дате добавления"
        
        var id: String { rawValue }
    }
    
    enum DisplayMode: String, CaseIterable, Identifiable {
        case grid = "Сетка"
        case list = "Список"
        
        var id: String { rawValue }
    }
}
