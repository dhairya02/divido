import Foundation
import Combine

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The API URL could not be constructed."
        case .invalidResponse: return "The server returned an invalid response."
        case .unauthorized: return "Please log in again to continue."
        case .server(let message): return message
        }
    }
}

@MainActor
final class APIClient: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isPerformingRequest = false

    private let baseURL: URL

    var currentToken: String? {
        KeychainService.shared.getToken()
    }

    init(baseURL: URL = URL(string: "https://example.org/api")!) {
        self.baseURL = baseURL
    }

    func signOut() {
        currentUser = nil
        KeychainService.shared.deleteToken()
    }

    func refreshProfile() async throws {
        let profile: AccountProfile = try await request("/account")
        currentUser = profile.user
    }

    func updateAccount(using requestBody: UpdateAccountRequest) async throws -> AccountProfile {
        try await request("/account", method: "PATCH", body: requestBody)
    }

    private func request<Response: Decodable, Body: Encodable>(
        _ path: String,
        method: String = "GET",
        body: Body? = nil
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        isPerformingRequest = true
        defer { isPerformingRequest = false }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return try JSONDecoder().decode(Response.self, from: data)
        case 401:
            throw APIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.server(message)
        }
    }
}
