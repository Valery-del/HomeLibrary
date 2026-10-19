import Foundation

final class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    func fetchBook(by isbn: String) async throws -> OpenLibraryBookData {
        let clean = isbn.filter { $0.isNumber }
        guard !clean.isEmpty else {
            throw NetworkError.invalidISBN
        }
        
        let urlString = "https://openlibrary.org/api/books?bibkeys=ISBN:\(clean)&jscmd=data&format=json"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidISBN
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError
        }
        
        let dict = try JSONDecoder().decode([String: OpenLibraryBookData].self, from: data)
        
        guard let book = dict["ISBN:\(clean)"] else {
            throw NetworkError.notFound
        }
        
        return book
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidISBN
    case serverError
    case notFound
    case alreadyExists
    
    var errorDescription: String? {
        switch self {
        case .invalidISBN: return "Некорректный ISBN"
        case .serverError: return "Ошибка сервера"
        case .notFound: return "Книга не найдена"
        case .alreadyExists: return "Эта книга уже есть в библиотеке"
        }
    }
}

struct OpenLibraryBookData: Decodable {
    let title: String?
    let authors: [AuthorInfo]?
    let number_of_pages: Int?
    let publish_date: String?
    let cover: CoverInfo?
    let subjects: [SubjectInfo]?
    
    struct AuthorInfo: Decodable {
        let name: String?
        let url: String?
    }
    
    struct CoverInfo: Decodable {
        let small: String?
        let medium: String?
        let large: String?
    }
    
    struct SubjectInfo: Decodable {
        let name: String?
        let url: String?
    }
}
