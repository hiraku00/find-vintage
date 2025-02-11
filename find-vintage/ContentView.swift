import SwiftUI
import UIKit

// 検索結果のデータモデル
struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let description: String
}

// ロード中View
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            ProgressView()
                .scaleEffect(2.0, anchor: .center)
                .tint(.white)
        }
    }
}

// カメラ
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }

            parent.dismiss()
        }
    }
}

struct ErrorAlertView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack {
                Text("エラー")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                Text(message)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

struct SearchResultsView: View {
    let results: [SearchResult]

    var body: some View {
        List(results) { result in
            VStack(alignment: .leading) {
                AsyncImage(url: URL(string: result.url)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                } placeholder: {
                    ProgressView()
                }
                Text(result.title)
                    .font(.headline)
                Text(result.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Link("詳細を見る", destination: URL(string: result.url)!)
                    .font(.caption)
            }
        }
    }
}


struct ContentView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var isShowingCamera = false
    @State private var isShowingSearchResults = false
    @State private var searchResults: [SearchResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let googleAPIKey: String = {
        guard let key = ProcessInfo.processInfo.environment["GOOGLE_CLOUD_VISION_API_KEY"] else {
            fatalError("GOOGLE_CLOUD_VISION_API_KEY not found in environment variables")
        }
        return key
    }()

    var body: some View {
        NavigationView {
            NavigationStack {
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
                 .navigationDestination(isPresented: $isShowingSearchResults) {
                    SearchResultsView(results: searchResults)
                }
                .overlay(
                    isLoading ? LoadingView() : nil
                )
                .overlay(
                    Group {
                        if let error = errorMessage {
                            ErrorAlertView(message: error)
                        }
                    }
                )
            }
        }
    }

    // 検索開始
    private func startSearch(image: UIImage) {
        isLoading = true
        errorMessage = nil

        searchSimilarImages(image: image) { results in
            isLoading = false
            if results.isEmpty {
                errorMessage = "類似画像が見つかりませんでした"
            } else {
                searchResults = results
                isShowingSearchResults = true
            }
        }
    }

    private func searchSimilarImages(image: UIImage, completion: @escaping ([SearchResult]) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion([])
            return
        }

        let base64EncodedImage = imageData.base64EncodedString()

        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64EncodedImage],
                    "features": [["type": "WEB_DETECTION"]]
                ]
            ]
        ]

        guard let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)") else {
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            errorMessage = "リクエスト作成エラー: \(error.localizedDescription)"
            completion([])
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "通信エラー: \(error.localizedDescription)"
                    completion([])
                    return
                }

                // HTTPレスポンスの確認
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        self.errorMessage = "HTTPエラー: \(httpResponse.statusCode)"
                        completion([])
                        return
                    }
                }

                guard let data = data else {
                    self.errorMessage = "データがありません"
                    completion([])
                    return
                }

                // レスポンスデータの確認（デバッグ用）
                if let responseString = String(data: data, encoding: .utf8) {
                    print("API Response: \(responseString)")
                }

                let allResults = self.parseVisionResponse(data: data)
                let limitedResults = Array(allResults.prefix(5)) // 最初の5件のみを取得
                completion(limitedResults)
            }
        }.resume()
    }

    private func parseVisionResponse(data: Data) -> [SearchResult] {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let responses = json?["responses"] as? [[String: Any]],
                  let webDetection = responses.first?["webDetection"] as? [String: Any] else {
                return []
            }

            var results: [SearchResult] = []

            // Web Entities
            if let webEntities = webDetection["webEntities"] as? [[String: Any]] {
                results += webEntities.compactMap { entity in
                    guard let description = entity["description"] as? String,
                          let entityId = entity["entityId"] as? String else {
                        return nil
                    }
                    return SearchResult(title: description, url: "https://www.google.com/search?q=\(description)", description: "Web Entity")//修正
                }
            }

            // Visually Similar Images
            if let visuallySimilarImages = webDetection["visuallySimilarImages"] as? [[String: Any]] {
                results += visuallySimilarImages.compactMap { image in
                    guard let url = image["url"] as? String else {
                        return nil
                    }
                    // タイトルを "類似画像" から URL に変更
                    return SearchResult(title: "類似画像", url: url, description: "視覚的に類似する画像")//修正
                }
            }

            return results
        } catch {
            print("JSON Parsing Error: \(error)")
            return []
        }
    }
}
