import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class LibraryViewModel {
    var searchText = ""
    var selectedStatus: ReadingStatus? = nil
    
    private let network = NetworkService.shared
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addBookFromISBN(_ isbn: String) async throws {
        let cleanISBN = isbn.filter { $0.isNumber }
        
        // === Проверка на дубликат ===
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.isbn == cleanISBN }
        )
        
        let existingBooks = try modelContext.fetch(descriptor)
        if !existingBooks.isEmpty {
            throw NetworkError.alreadyExists
        }
        // ============================
        
        let bookData = try await network.fetchBook(by: cleanISBN)
        
        let coverURL = bookData.cover?.medium
        ?? bookData.cover?.large
        ?? "https://covers.openlibrary.org/b/isbn/\(cleanISBN)-M.jpg"
        
        let year: Int? = {
            guard let date = bookData.publish_date else { return nil }
            let digits = date.filter { $0.isNumber }
            guard digits.count >= 4 else { return nil }
            return Int(digits.prefix(4))
        }()
        
        let newBook = Book(
            title: bookData.title ?? "Без названия",
            isbn: cleanISBN,
            year: year,
            coverURL: coverURL,
            status: .planned
        )
        
        if let authors = bookData.authors {
            for a in authors {
                if let name = a.name, !name.isEmpty {
                    let author = Author(name: name)
                    modelContext.insert(author)
                    newBook.authors.append(author)
                }
            }
        }
        
        if let subjects = bookData.subjects?.prefix(5) {
            for s in subjects {
                if let name = s.name, !name.isEmpty {
                    let genre = Genre(name: name)
                    modelContext.insert(genre)
                    newBook.genres.append(genre)
                }
            }
        }
        
        modelContext.insert(newBook)
        try modelContext.save()
    }
    
    func delete(_ book: Book) {
        modelContext.delete(book)
        try? modelContext.save()
    }
}
