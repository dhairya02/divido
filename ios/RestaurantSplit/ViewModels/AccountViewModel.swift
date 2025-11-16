import Foundation
import SwiftUI
import Combine

@MainActor
final class AccountViewModel: ObservableObject {
    @Published var profile: AccountProfile = .placeholder
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var preferredCurrency: String = "USD"
    @Published var notificationsEnabled: Bool = true

    private var cancellables: Set<AnyCancellable> = []

    private let apiClient: APIClient

    init(apiClient: APIClient = SessionController.shared.apiClient) {
        self.apiClient = apiClient
        bindProfile()
    }

    private func bindProfile() {
        apiClient.$currentUser
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                self.profile.user = user
                self.preferredCurrency = self.profile.preferredCurrency
                self.notificationsEnabled = self.profile.notificationsEnabled
            }
            .store(in: &cancellables)
    }

    func loadProfile() async {
        await perform {
            try await apiClient.refreshProfile()
            self.profile = AccountProfile(user: apiClient.currentUser ?? self.profile.user,
                                          preferredCurrency: self.preferredCurrency,
                                          notificationsEnabled: self.notificationsEnabled)
        }
    }

    func saveChanges() async {
        await perform {
            let body = UpdateAccountRequest(name: profile.user.name,
                                            preferredCurrency: preferredCurrency,
                                            notificationsEnabled: notificationsEnabled)
            let updated = try await apiClient.updateAccount(using: body)
            self.profile = updated
        }
    }

    func logout() {
        apiClient.signOut()
    }

    private func perform(_ work: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await work()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}
