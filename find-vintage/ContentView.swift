import SwiftUI
import UIKit

struct ContentView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var isShowingCamera = false
    @State private var isShowingSearchResults = false
    @State private var searchResults: [SearchResult] = []
    @State private var isLoading = false

    // 環境変数からAPIキーと検索エンジンIDを取得
    private let googleAPIKey: String = {
        guard let key = ProcessInfo.processInfo.environment["GOOGLE_CUSTOM_SEARCH_API_KEY"] else {
            fatalError("GOOGLE_CUSTOM_SEARCH_API_KEY not found in environment variables")
        }
        return key
    }()

    private let searchEngineID: String = {
        guard let id = ProcessInfo.processInfo.environment["GOOGLE_CUSTOM_SEARCH_ENGINE_ID"] else {
            fatalError("GOOGLE_CUSTOM_SEARCH_ENGINE_ID not found in environment variables")
        }
        return id
    }()

    var body: some View {
        NavigationView {
            NavigationStack { // NavigationStack で囲む
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
                // NavigationLinkを削除し、navigationDestinationを使用
                .navigationDestination(isPresented: $isShowingSearchResults) {
                    SearchResultsView(results: searchResults)
                }
                .overlay(
                    isLoading ? LoadingView() : nil
                )
            }
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
       guard let imageData = image.jpegData(compressionQuality: 0.8) else {
           completion([])
           return
       }

       let urlString = "https://www.googleapis.com/customsearch/v1"
       var components = URLComponents(string: urlString)!
       components.queryItems = [
           URLQueryItem(name: "key", value: googleAPIKey),
           URLQueryItem(name: "cx", value: searchEngineID),
           URLQueryItem(name: "searchType", value: "image")
       ]

       guard let url = components.url else {
           completion([])
           return
       }

       var request = URLRequest(url: url)
       request.httpMethod = "POST"
       request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type") // Content-Typeの設定

       // APIリクエストのbodyに画像データを設定
       request.httpBody = imageData

       URLSession.shared.dataTask(with: request) { data, response, error in
           if let error = error {
               print("API Error: \(error)")
               completion([])
               return
           }

           // HTTPステータスコードの確認
           if let httpResponse = response as? HTTPURLResponse {
               if !(200...299).contains(httpResponse.statusCode) {
                   print("HTTP Status Code: \(httpResponse.statusCode)")
                   // エラーレスポンスの処理（例：エラーメッセージの出力）
                   if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                       print("Error Message from API: \(errorMessage)")
                   }
                   completion([])
                   return
               }
           }

           guard let data = data else {
               completion([])
               return
           }

           do {
               // JSONのパース
               let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
               let results = self.parseSearchResults(json: json)
               completion(results)
           } catch {
               print("JSON Parsing Error: \(error)")
               // エラーの原因を特定するための情報をログに出力
               if let jsonString = String(data: data, encoding: .utf8) {
                   print("Received JSON String: \(jsonString)")
               }
               completion([])
           }
       }.resume()
   }

    // 検索結果のパース
    private func parseSearchResults(json: [String: Any]?) -> [SearchResult] {
        guard let items = json?["items"] as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item in
            guard let title = item["title"] as? String,
                  let link = item["link"] as? String else {
                return nil
            }
            return SearchResult(title: title, link: link, confidence: 1.0)
        }
    }
}
