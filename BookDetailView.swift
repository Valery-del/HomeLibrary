import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Bindable var book: Book
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                AsyncImage(url: URL(string: book.coverURL ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Image(systemName: "book.closed")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
            }
            
            Section("Информация") {
                TextField("Название", text: $book.title)
                TextField("ISBN", text: Binding(
                    get: { book.isbn ?? "" },
                    set: { book.isbn = $0.isEmpty ? nil : $0 }
                ))
                Stepper("Год: \(book.year ?? 0)", value: Binding(
                    get: { book.year ?? 2000 },
                    set: { book.year = $0 }
                ), in: 1800...2030)
                
                Picker("Статус", selection: $book.status) {
                    ForEach(ReadingStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                
                HStack {
                    Text("Оценка")
                    Spacer()
                    Slider(value: $book.personalRating, in: 0...5, step: 0.5)
                    Text(String(format: "%.1f", book.personalRating))
                }
            }
            
            Section("Авторы") {
                ForEach(book.authors) { author in
                    Text(author.name)
                }
            }
            
            Section("Жанры") {
                ForEach(book.genres) { genre in
                    Text(genre.name)
                }
            }
            
            Section {
                TextField("Аннотация", text: Binding(
                    get: { book.annotation ?? "" },
                    set: { book.annotation = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(4...8)
            }
        }
        .navigationTitle("Карточка книги")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Удалить", role: .destructive) {
                    modelContext.delete(book)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }
}
