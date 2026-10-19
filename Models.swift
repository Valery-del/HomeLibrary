import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: UUID
    var title: String
    var isbn: String?
    var year: Int?
    var annotation: String?
    var coverURL: String?
    var personalRating: Double
    var status: ReadingStatus
    var dateAdded: Date
    
    @Relationship(deleteRule: .nullify) var authors: [Author] = []
    @Relationship(deleteRule: .nullify) var genres: [Genre] = []
    
    init(title: String,
         isbn: String? = nil,
         year: Int? = nil,
         annotation: String? = nil,
         coverURL: String? = nil,
         personalRating: Double = 0,
         status: ReadingStatus = .planned) {
        self.id = UUID()
        self.title = title
        self.isbn = isbn
        self.year = year
        self.annotation = annotation
        self.coverURL = coverURL
        self.personalRating = personalRating
        self.status = status
        self.dateAdded = .now
    }
}

@Model
final class Author {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(inverse: \Book.authors) var books: [Book] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

@Model
final class Genre {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(inverse: \Book.genres) var books: [Book] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case planned = "В планах"
    case reading = "Читаю"
    case finished = "Прочитано"
    
    var id: String { rawValue }
}
