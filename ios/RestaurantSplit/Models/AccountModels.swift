import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var email: String
    var joinedAt: Date

    init(id: UUID = UUID(), name: String, email: String, joinedAt: Date = .init()) {
        self.id = id
        self.name = name
        self.email = email
        self.joinedAt = joinedAt
    }
}

struct AccountProfile: Codable, Equatable {
    var user: User
    var preferredCurrency: String
    var notificationsEnabled: Bool

    static var placeholder: AccountProfile {
        .init(user: User(name: "Casey Splitter", email: "casey@example.com"), preferredCurrency: "USD", notificationsEnabled: true)
    }
}

struct UpdateAccountRequest: Encodable {
    var name: String
    var preferredCurrency: String
    var notificationsEnabled: Bool
}
