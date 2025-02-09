//
//  SearchResultsView.swift
//  find-vintage
//
//  Created by hiraku on 2025/02/09.
//


import SwiftUI

struct SearchResultsView: View {
    let results: [SearchResult]
    
    var body: some View {
        List(results, id: \.title) { result in
            VStack(alignment: .leading) {
                Text(result.title)
                    .font(.headline)
                Text("Confidence: \(Int(result.confidence * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Search Results")
    }
}