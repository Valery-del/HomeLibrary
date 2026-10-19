import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var authorName = ""
    @State private var isbn = ""
    @State private var year = ""
    @State private var status: ReadingStatus = .planned
    @State private var rating: Double = 0
    @State private var annotation = ""
    @State private var coverURL: String? = nil
    @State private var genresText = ""          
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("ISBN (для автоматической обложки и данных)") {
                    HStack {
                        TextField("ISBN", text: $isbn)
                            .keyboardType(.numberPad)
                        
                        Button("Найти") {
                            Task { await fetchFromISBN() }
                        }
                        .disabled(isbn.filter { $0.isNumber }.count < 10 || isLoading)
                    }
                    
                    if isLoading {
                        ProgressView("Ищем книгу...")
                    }
                    
                    if let coverURL, let url = URL(string: coverURL) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .cornerRadius(8)
                            } else {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Section("Основная информация") {
                    TextField("Название книги", text: $title)
                    TextField("Автор", text: $authorName)
                    TextField("Год издания", text: $year)
                        .keyboardType(.numberPad)
                    
                    // Поле для жанров
                    TextField("Жанры (через запятую)", text: $genresText)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Статус и оценка") {
                    Picker("Статус", selection: $status) {
                        ForEach(ReadingStatus.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    
                    HStack {
                        Text("Оценка")
                        Slider(value: $rating, in: 0...5, step: 0.5)
                        Text(String(format: "%.1f", rating))
                            .frame(width: 35)
                    }
                }
                
                Section("Аннотация") {
                    TextField("Краткое описание", text: $annotation, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Новая книга")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        saveBook()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Ошибка", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Загрузка по ISBN
    
    private func fetchFromISBN() async {
        let clean = isbn.filter { $0.isNumber }
        guard clean.count >= 10 else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let bookData = try await NetworkService.shared.fetchBook(by: clean)
            
            if title.isEmpty {
                title = bookData.title ?? ""
            }
            
            if authorName.isEmpty, let firstAuthor = bookData.authors?.first?.name {
                authorName = firstAuthor
            }
            
            if year.isEmpty, let date = bookData.publish_date {
                let digits = date.filter { $0.isNumber }
                if digits.count >= 4 {
                    year = String(digits.prefix(4))
                }
            }
            
            // Подтягиваем жанры из API
            if genresText.isEmpty, let subjects = bookData.subjects {
                let names = subjects.compactMap { $0.name }.prefix(5)
                genresText = names.joined(separator: ", ")
            }
            
            coverURL = bookData.cover?.medium
            ?? bookData.cover?.large
            ?? "https://covers.openlibrary.org/b/isbn/\(clean)-M.jpg"
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Сохранение
    
    private func saveBook() {
        let cleanISBN = isbn.filter { $0.isNumber }
        
        // Проверка дубликата по ISBN
        if !cleanISBN.isEmpty {
            let descriptor = FetchDescriptor<Book>(
                predicate: #Predicate { $0.isbn == cleanISBN }
            )
            if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
                errorMessage = "Эта книга уже есть в библиотеке"
                return
            }
        }
        
        // Проверка дубликата по названию + автору
        if cleanISBN.isEmpty {
            let titleToCheck = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let authorToCheck = authorName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let allBooks = try? modelContext.fetch(FetchDescriptor<Book>()) {
                let isDuplicate = allBooks.contains { book in
                    book.title.localizedCaseInsensitiveCompare(titleToCheck) == .orderedSame &&
                    (authorToCheck.isEmpty || book.authors.contains {
                        $0.name.localizedCaseInsensitiveCompare(authorToCheck) == .orderedSame
                    })
                }
                
                if isDuplicate {
                    errorMessage = "Такая книга уже есть в библиотеке"
                    return
                }
            }
        }
        
        let newBook = Book(
            title: title.trimmingCharacters(in: .whitespaces),
            isbn: cleanISBN.isEmpty ? nil : cleanISBN,
            year: Int(year),
            annotation: annotation.isEmpty ? nil : annotation,
            coverURL: coverURL,
            personalRating: rating,
            status: status
        )
        
        // Автор
        if !authorName.trimmingCharacters(in: .whitespaces).isEmpty {
            let author = Author(name: authorName.trimmingCharacters(in: .whitespaces))
            modelContext.insert(author)
            newBook.authors.append(author)
        }
        
        // Жанры (разбиваем строку по запятой)
        let genreNames = genresText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for name in genreNames {
            let genre = Genre(name: name)
            modelContext.insert(genre)
            newBook.genres.append(genre)
        }
        
        modelContext.insert(newBook)
        try? modelContext.save()
        dismiss()
    }
}
