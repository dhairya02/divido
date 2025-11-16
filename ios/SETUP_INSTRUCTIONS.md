# iOS Project Setup Instructions

Since Xcode projects require the IDE to properly initialize, follow these steps to create the SwiftUI app:

## Step 1: Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Configure:
   - Product Name: `RestaurantSplit`
   - Team: Your development team
   - Organization Identifier: `com.yourname` (use your own)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None
   - Include Tests: ✅ Yes
5. Save to: `/Users/upadhd02/Downloads/Random/Bill_splitter/RestaurantSplit/ios/`

## Step 2: Configure Project Settings

### General Tab
- **Deployment Target**: iOS 26.0
- **Supported Destinations**: iPhone
- **Bundle Identifier**: `com.yourname.RestaurantSplit`

### Info Tab
Add custom fonts:
- Key: "Fonts provided by application" (UIAppFonts)
- Add: `EBGaramond-Regular.ttf` (download from Google Fonts)

### Signing & Capabilities
- Enable "Automatic manage signing"
- Select your development team

## Step 3: Create Folder Structure

In Xcode Project Navigator, create groups:
```
RestaurantSplit/
├── App/
│   └── RestaurantSplitApp.swift (move here)
├── Models/
├── Services/
├── ViewModels/
├── Views/
│   ├── Authentication/
│   ├── Bills/
│   ├── Contacts/
│   ├── Balances/
│   ├── Account/
│   └── Components/
├── Assets.xcassets/
└── Fonts/
```

## Step 4: Add Assets

### Colors (Assets.xcassets → New Color Set)
1. **Primary**
   - Any Appearance: #6F8BFF
2. **PrimaryAccent**
   - Any Appearance: #E6FDA3
3. **Success**
   - Any Appearance: #065F46
4. **Error**
   - Any Appearance: #DC2626

### App Icon
- Use logo from `packages/ui-assets/restaurantsplit-high-resolution-logo.png`
- Generate app icon sizes (use online tool or Xcode asset catalog)

### Fonts
1. Download EB Garamond from Google Fonts
2. Add .ttf files to Fonts/ folder
3. Add to target membership
4. Register in Info.plist

## Step 5: Initial Code Setup

### 1. Create APIClient.swift in Services/

```swift
import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
}

@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()
    
    private let baseURL: String
    private var authToken: String?
    
    init(baseURL: String = "http://localhost:3000/api") {
        self.baseURL = baseURL
        self.authToken = KeychainService.shared.getToken()
    }
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
        if let token = token {
            KeychainService.shared.saveToken(token)
        } else {
            KeychainService.shared.deleteToken()
        }
    }
    
    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        default:
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMsg)
        }
    }
}
```

### 2. Create KeychainService.swift in Services/

```swift
import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    private let service = "com.yourname.RestaurantSplit"
    private let account = "authToken"
    
    func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
```

### 3. Create Models (Models/User.swift, etc.)

```swift
// Models/User.swift
import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String?
    let email: String?
}

// Models/Contact.swift
struct Contact: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let venmo: String?
    let cashapp: String?
    let isTemporary: Bool
}

// Models/Bill.swift
struct Bill: Codable, Identifiable {
    let id: String
    let title: String
    let venue: String?
    let subtotalCents: Int
    let taxRatePct: Double
    let tipRatePct: Double
    let convenienceFeeRatePct: Double
    let currency: String
    let paidByContactId: String?
}

// More models following packages/shared/models.ts
```

### 4. Update RestaurantSplitApp.swift

```swift
import SwiftUI

@main
struct RestaurantSplitApp: App {
    @StateObject private var apiClient = APIClient.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiClient)
        }
    }
}
```

### 5. Create ContentView with Navigation

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var isAuthenticated = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView()
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
            }
        }
        .onAppear {
            isAuthenticated = KeychainService.shared.getToken() != nil
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            BillsListView()
                .tabItem {
                    Label("Bills", systemImage: "doc.text")
                }
            
            ContactsListView()
                .tabItem {
                    Label("Contacts", systemImage: "person.2")
                }
            
            BalancesView()
                .tabItem {
                    Label("Balances", systemImage: "dollarsign.circle")
                }
            
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
        }
    }
}
```

## Step 6: Build & Run

1. Select iPhone simulator (iPhone 17 Pro)
2. Build (⌘B)
3. Run (⌘R)

## Step 7: Test with Backend

1. Start Next.js backend:
   ```bash
   cd web && pnpm dev
   ```
2. Update APIClient baseURL if needed
3. Test login flow

## Next Phase: Implement Views

Follow the implementation plan in `README.md` to build out:
1. Authentication views
2. Bills list
3. Bill detail with items
4. And so on...

## Troubleshooting

### "Command PhaseScriptExecution failed"
- Clean build folder (⌘⇧K)
- Delete derived data

### Font not loading
- Check Info.plist UIAppFonts array
- Verify font is added to target membership

### Network requests failing
- Check baseURL in APIClient
- Ensure backend is running
- Check iOS simulator network settings

### Keychain errors
- Reset simulator if persistent issues
- Check service/account identifiers match

