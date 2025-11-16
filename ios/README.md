# RestaurantSplit iOS

Native iOS application for fair bill splitting, built with SwiftUI.

## Project Setup

This Xcode project will be initialized with the following structure:

```
ios/
├── RestaurantSplit.xcodeproj/
├── RestaurantSplit/
│   ├── RestaurantSplitApp.swift       # App entry point
│   ├── Models/                         # Data models
│   │   ├── User.swift
│   │   ├── Contact.swift
│   │   ├── Bill.swift
│   │   ├── Item.swift
│   │   └── Calculation.swift
│   ├── Services/                       # Networking & utilities
│   │   ├── APIClient.swift
│   │   ├── AuthService.swift
│   │   └── KeychainService.swift
│   ├── ViewModels/                     # MVVM view models
│   │   ├── AuthViewModel.swift
│   │   ├── BillsViewModel.swift
│   │   ├── BillDetailViewModel.swift
│   │   ├── ContactsViewModel.swift
│   │   └── BalancesViewModel.swift
│   ├── Views/                          # SwiftUI views
│   │   ├── Authentication/
│   │   │   ├── LoginView.swift
│   │   │   └── RegisterView.swift
│   │   ├── Bills/
│   │   │   ├── BillsListView.swift
│   │   │   ├── BillDetailView.swift
│   │   │   ├── NewBillView.swift
│   │   │   └── ItemShareMatrixView.swift
│   │   ├── Contacts/
│   │   │   └── ContactsListView.swift
│   │   ├── Balances/
│   │   │   └── BalancesView.swift
│   │   ├── Account/
│   │   │   └── AccountView.swift
│   │   └── Components/
│   │       ├── CustomButton.swift
│   │       ├── CustomTextField.swift
│   │       └── MoneyText.swift
│   ├── Assets.xcassets/                # Images and colors
│   │   ├── Colors/
│   │   │   ├── Primary.colorset
│   │   │   ├── PrimaryAccent.colorset
│   │   │   └── Success.colorset
│   │   └── AppIcon.appiconset
│   ├── Fonts/                          # EB Garamond .ttf files
│   └── Info.plist
├── RestaurantSplitTests/              # Unit tests
└── RestaurantSplitUITests/            # UI tests
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Key Features to Implement

### Phase 1: Foundation (Proof of Concept)
- ✅ Project structure setup
- ✅ API client with Combine
- ✅ Auth flow (Login/Register)
- ✅ Bills list view
- ✅ Basic navigation

### Phase 2: Core Features
- Bill detail view with items
- Add/edit items
- Participant management
- Share weight editor (pill-based UI)
- Bill calculation display

### Phase 3: Advanced Features
- Item share matrix with sticky headers
- Receipt OCR using Vision
- Contact management
- Balance tracking
- Export to image

### Phase 4: Polish
- Quick split flow
- Account settings
- Dark mode support
- Accessibility
- Error handling & loading states

## Architecture Patterns

### MVVM (Model-View-ViewModel)

```swift
// View
struct BillsListView: View {
    @StateObject private var viewModel = BillsViewModel()
    
    var body: some View {
        List(viewModel.bills) { bill in
            // UI
        }
        .task { await viewModel.loadBills() }
    }
}

// ViewModel
@MainActor
class BillsViewModel: ObservableObject {
    @Published var bills: [Bill] = []
    private let apiClient = APIClient.shared
    
    func loadBills() async {
        bills = try? await apiClient.getBills()
    }
}
```

### API Client with Combine

```swift
class APIClient {
    static let shared = APIClient()
    private let baseURL = "http://localhost:3000/api"
    
    func request<T: Decodable>(_ endpoint: String) async throws -> T {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

## Design System Integration

### Colors
Colors are defined in Assets.xcassets and match the web design:

```swift
extension Color {
    static let primary = Color("Primary")        // #6f8bff
    static let primaryAccent = Color("PrimaryAccent")  // #E6FDA3
    static let success = Color("Success")        // #065f46
    static let error = Color("Error")            // #dc2626
}
```

### Typography
EB Garamond custom font loaded via Info.plist:

```swift
extension Font {
    static func garamond(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .custom("EBGaramond-Regular", size: size)
    }
}
```

### Components
Reusable components matching web design:

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.garamond(16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .cornerRadius(6)
        }
    }
}
```

## API Integration

Base URL should point to your Next.js backend:
- Development: `http://localhost:3000/api`
- Production: `https://your-domain.com/api`

Configure in `APIClient.swift` or via environment variables.

## Authentication Flow

1. User enters credentials
2. POST to `/api/auth/signin`
3. Receive JWT token
4. Store in Keychain
5. Attach to subsequent requests via Authorization header

## Next Steps

1. Create Xcode project with SwiftUI App template
2. Set up folder structure
3. Add EB Garamond font files
4. Configure asset catalog with colors
5. Implement APIClient + auth flow
6. Build login/register views
7. Implement bills list as proof of concept

