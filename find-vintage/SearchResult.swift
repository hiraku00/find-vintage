import Foundation

struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let confidence: Double
}
