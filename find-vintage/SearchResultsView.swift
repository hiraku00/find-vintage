import SwiftUI

struct SearchResultsView: View {
    let results: [SearchResult]
    
    var body: some View {
        List(results) { result in
            VStack(alignment: .leading) {
                Text(result.title)
                    .font(.headline)
                Text(result.link)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        if let url = URL(string: result.link) {
                            UIApplication.shared.open(url)
                        }
                    }
            }
        }
        .navigationTitle("Search Results")
    }
}
