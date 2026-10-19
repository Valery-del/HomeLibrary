import SwiftUI
import AVFoundation

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    var onScan: (String) -> Void
    
    // Mock ISBN для Playgrounds / симулятора
    private let mockISBNs = [
        "9780140328721",
        "9780931917394",
        "9780743273565",
        "9780061120084",
        "9780316769488"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Сканирование ISBN")
                    .font(.title2.bold())
                
                Text("В Playgrounds камера работает ограниченно.\nИспользуй mock-кнопки ниже.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
                
                ForEach(mockISBNs, id: \.self) { isbn in
                    Button {
                        onScan(isbn)
                        dismiss()
                    } label: {
                        Text("Mock: \(isbn)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}
