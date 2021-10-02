import SwiftUI

struct Cat: Hashable, Identifiable, Decodable {
    let id: String
    var url: URL {
        URL(string: "https://cataas.com/cat/\(id)")!
    }
}

@MainActor
class CatsViewModel: ObservableObject {
    @Published var cats = [Cat]()
    
    func refresh() async {
        cats = await fetch()
    }
    
    private func fetch() async -> [Cat] {
        let request = URLRequest(url: URL(string: "https://cataas.com/api/cats?limit=50")!)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            // Error handling and response status checking omitted for simplicity
            return try JSONDecoder().decode([Cat].self, from: data)
        } catch {
            print("Oh oh \(error)")
            return []
        }
    }
}

struct CatView: View {
    let cat: Cat
    var body: some View {
        VStack {
            AsyncImage(url: cat.url, transaction: Transaction(animation: .easeInOut)) { phase in
                switch phase {
                case .empty:
                    Color.gray
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure(_):
                    Color.red
                @unknown default:
                    Color.gray
                }
            }
                .frame(width: 100, height: 100)
                .background(Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            Text("Some Cat").font(.caption)
        }
    }
}

struct ContentView: View {
    @StateObject var viewModel = CatsViewModel()
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.cats) { cat in
                    CatView(cat: cat)
                }
            }
            .padding(.horizontal)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.refresh()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
