import SwiftUI
import Combine

@MainActor
final class SessionController: ObservableObject {
    static let shared = SessionController()

    @Published var isAuthenticated: Bool
    @Published var activeUser: User?

    let apiClient: APIClient

    private var cancellables: Set<AnyCancellable> = []

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
        self.isAuthenticated = apiClient.currentToken != nil

        apiClient.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.activeUser = user
                self?.isAuthenticated = user != nil
            }
            .store(in: &cancellables)
    }

    func signOut() {
        apiClient.signOut()
    }
}

@main
struct RestaurantSplitApp: App {
    @StateObject private var session = SessionController.shared
    @StateObject private var theme = Theme()

    var body: some Scene {
        WindowGroup {
            AccountView()
                .environmentObject(session)
                .environmentObject(theme)
        }
    }
}
