import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBooks: [Book]
    
    @State private var viewModel: LibraryViewModel?
    @State private var settings = SettingsStore()
    @State private var showScanner = false
    @State private var showSettings = false
    @State private var showAddBook = false
    @State private var errorMessage: String?
    
    // Фильтры
    @State private var selectedStatus: ReadingStatus? = nil
    @State private var selectedGenre: String? = nil
    
    var body: some View {
        NavigationStack {
            mainContent
                .searchable(text: searchBinding, prompt: "Автор или название")
                .navigationTitle("Моя библиотека")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showScanner) {
                    ScannerView { isbn in
                        Task {
                            do {
                                try await viewModel?.addBookFromISBN(isbn)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(settings: settings)
                }
                .sheet(isPresented: $showAddBook) {
                    AddBookView()
                }
                .navigationDestination(for: Book.self) { book in
                    BookDetailView(book: book)
                }
                .alert("Ошибка", isPresented: errorBinding) {
                    Button("OK") { errorMessage = nil }
                } message: {
                    Text(errorMessage ?? "")
                }
                .task {
                    if viewModel == nil {
                        viewModel = LibraryViewModel(modelContext: modelContext)
                    }
                }
        }
    }
    
    // MARK: - Основной контент
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Фильтры по статусу
            statusFilterBar
            
            // Фильтр по жанрам (если есть жанры)
            if !allGenres.isEmpty {
                genreFilterBar
            }
            
            if let viewModel {
                if settings.displayMode == .grid {
                    gridView(books: filteredAndSortedBooks)
                } else {
                    listView(books: filteredAndSortedBooks)
                }
            } else {
                ProgressView("Загрузка...")
            }
        }
    }
    
    // MARK: - Фильтры
    
    private var statusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Все", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                
                ForEach(ReadingStatus.allCases) { status in
                    FilterChip(title: status.rawValue, isSelected: selectedStatus == status) {
                        selectedStatus = status
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
    
    private var genreFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Все жанры", isSelected: selectedGenre == nil) {
                    selectedGenre = nil
                }
                
                ForEach(allGenres, id: \.self) { genre in
                    FilterChip(title: genre, isSelected: selectedGenre == genre) {
                        selectedGenre = genre
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Сетка и список
    
    private func gridView(books: [Book]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 16) {
                ForEach(books) { book in
                    NavigationLink(value: book) {
                        BookCoverView(book: book)
                    }
                }
            }
            .padding()
        }
    }
    
    private func listView(books: [Book]) -> some View {
        List {
            ForEach(books) { book in
                NavigationLink(value: book) {
                    BookRowView(book: book)
                }
            }
            .onDelete { indexSet in
                for i in indexSet {
                    viewModel?.delete(books[i])
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                showAddBook = true
            } label: {
                Image(systemName: "plus")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                showScanner = true
            } label: {
                Label("Сканировать", systemImage: "barcode.viewfinder")
            }
        }
    }
    
    // MARK: - Данные и фильтры
    
    private var allGenres: [String] {
        let genres = allBooks.flatMap { $0.genres.map(\.name) }
        return Array(Set(genres)).sorted()
    }
    
    private var filteredAndSortedBooks: [Book] {
        var result = allBooks
        
        // Поиск
        if let vm = viewModel, !vm.searchText.isEmpty {
            let text = vm.searchText
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(text) ||
                $0.authors.contains { $0.name.localizedCaseInsensitiveContains(text) }
            }
        }
        
        // Фильтр по статусу
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }
        
        // Фильтр по жанру
        if let genre = selectedGenre {
            result = result.filter { $0.genres.contains { $0.name == genre } }
        }
        
        // Сортировка
        switch settings.sortOrder {
        case .title:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:
            result.sort {
                let a1 = $0.authors.first?.name ?? ""
                let a2 = $1.authors.first?.name ?? ""
                return a1.localizedCompare(a2) == .orderedAscending
            }
        case .year:
            result.sort { ($0.year ?? 0) > ($1.year ?? 0) }
        case .rating:
            result.sort { $0.personalRating > $1.personalRating }
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        }
        
        return result
    }
    
    private var searchBinding: Binding<String> {
        Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        )
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }
}

// MARK: - Чип фильтра

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
