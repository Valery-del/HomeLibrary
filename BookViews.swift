import SwiftUI

struct BookCoverView: View {
    let book: Book
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: book.coverURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                default:
                    Image(systemName: "book.closed")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(book.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(4)
    }
}

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: book.coverURL ?? "")) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 50, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading) {
                Text(book.title).font(.headline)
                Text(book.authors.map(\.name).joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(book.status.rawValue)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
}
