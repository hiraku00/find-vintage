import SwiftUI
import UIKit

struct ContentView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var isShowingCamera = false
    @State private var isShowingSearchResults = false
    @State private var searchResults: [SearchResult] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // プレビュー画像
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                } else {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Text("No Image")
                            .foregroundColor(.gray)
                    }
                    .frame(height: 300)
                    .cornerRadius(12)
                }
                
                // カメラボタン
                Button(action: {
                    isShowingCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // 検索ボタン
                Button(action: {
                    if let image = capturedImage {
                        startSearch(image: image)
                    }
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search Similar Items")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(capturedImage == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(capturedImage == nil)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Find Vintage")
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(image: $capturedImage)
            }
            .background(
                NavigationLink(
                    destination: SearchResultsView(results: searchResults),
                    isActive: $isShowingSearchResults,
                    label: { EmptyView() }
                )
            )
            .overlay(
                isLoading ? LoadingView() : nil
            )
        }
    }
    
    // 検索開始
    private func startSearch(image: UIImage) {
        isLoading = true
        
        // Google Custom Search API を呼び出す
        uploadImageToGoogleSearch(image: image) { results in
            isLoading = false
            searchResults = results
            isShowingSearchResults = true
        }
    }
    
    // Google Custom Search API への画像アップロード
    private func uploadImageToGoogleSearch(image: UIImage, completion: @escaping ([SearchResult]) -> Void) {
        // ここにAPIリクエストの実装を追加
        // ダミーデータを返す
        let dummyResults = [
            SearchResult(title: "Vintage T-Shirt", confidence: 0.95),
            SearchResult(title: "Retro Jeans", confidence: 0.90),
            SearchResult(title: "Classic Jacket", confidence: 0.85)
        ]
        completion(dummyResults)
    }
}
