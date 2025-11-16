# RestaurantSplit iOS Implementation Roadmap

## Current Status

✅ **Phase 1: Preparation (COMPLETED)**
- Repository restructured into monorepo layout
- Shared contracts and models documented
- Design system extracted to `packages/ui-assets/`
- Architecture documented

## Next Steps

### Phase 2: iOS Foundation (2-3 days)

**Task 2.1: Create Xcode Project**
- [ ] Follow `ios/SETUP_INSTRUCTIONS.md` to create project in Xcode
- [ ] Configure deployment target, bundle ID, signing
- [ ] Set up folder structure
- [ ] Add color assets to Assets.xcassets

**Task 2.2: Add Fonts & Assets**
- [ ] Download EB Garamond from Google Fonts
- [ ] Add font files to project
- [ ] Configure Info.plist for custom fonts
- [ ] Copy logo from `packages/ui-assets/`
- [ ] Generate app icon from logo

**Task 2.3: Core Services**
- [ ] Implement `APIClient.swift` with async/await
- [ ] Implement `KeychainService.swift` for token storage
- [ ] Create base models matching `packages/shared/models.ts`
- [ ] Add error handling and logging

**Task 2.4: Authentication Flow**
- [ ] Create `AuthViewModel.swift`
- [ ] Build `LoginView.swift` matching web design
- [ ] Build `RegisterView.swift`
- [ ] Implement auth state management
- [ ] Connect to `/api/auth` endpoints

### Phase 3: Core Features - Bills (5-7 days)

**Task 3.1: Bills List**
- [ ] Create `BillsViewModel.swift`
- [ ] Build `BillsListView.swift`
  - [ ] Match web design (cards with subtotal)
  - [ ] Pull-to-refresh
  - [ ] Navigation to detail
- [ ] Connect to `/api/bills` endpoint

**Task 3.2: Bill Detail**
- [ ] Create `BillDetailViewModel.swift`
- [ ] Build `BillDetailView.swift`
  - [ ] Header with title, venue, payee selector
  - [ ] Edit bill details inline
  - [ ] Items list with edit/delete
- [ ] Connect to `/api/bills/[id]` endpoint

**Task 3.3: Add/Edit Items**
- [ ] Build `AddItemView.swift` sheet
- [ ] Build `EditItemView.swift` sheet
- [ ] Implement quantity, taxable, tax rate fields
- [ ] Connect to `/api/bills/[id]/items` endpoints

**Task 3.4: Participants**
- [ ] Build participant picker component
- [ ] Add participant flow
- [ ] Connect to `/api/bills/[id]/participants`

**Task 3.5: Item Share Editor**
- [ ] Build pill-based participant selector (matching `ItemShareEditor.tsx`)
- [ ] Implement weight adjustment
- [ ] "Split equally" functionality
- [ ] Save shares to API

**Task 3.6: Calculation & Display**
- [ ] Build summary table view (matching web export view)
- [ ] Connect to `/api/bills/[id]/calc`
- [ ] Display per-person breakdown
- [ ] Display by-item matrix

**Task 3.7: New Bill Flow**
- [ ] Build `NewBillView.swift`
- [ ] Form with all bill fields
- [ ] Participant selection
- [ ] Create bill endpoint integration

### Phase 4: Item Share Matrix (3-4 days)

**Task 4.1: Matrix View Structure**
- [ ] Create `ItemShareMatrixView.swift`
- [ ] Implement scrollable grid layout
- [ ] Build sticky header row
- [ ] Build sticky first column

**Task 4.2: Cell Interactions**
- [ ] Checkbox for include/exclude
- [ ] Weight input field
- [ ] Row/column highlighting on interaction
- [ ] Active cell bolding

**Task 4.3: Data Management**
- [ ] Track dirty state
- [ ] Batch save changes
- [ ] Optimistic UI updates
- [ ] Error handling

**Task 4.4: Performance**
- [ ] Lazy loading for large matrices
- [ ] Debounced API calls
- [ ] Memory optimization

### Phase 5: Additional Features (4-5 days)

**Task 5.1: Contacts**
- [ ] Create `ContactsViewModel.swift`
- [ ] Build `ContactsListView.swift`
- [ ] Build `AddContactView.swift` sheet
- [ ] Build `EditContactView.swift` sheet
- [ ] Sorting (first/last name)
- [ ] Delete functionality

**Task 5.2: Balances**
- [ ] Create `BalancesViewModel.swift`
- [ ] Build `BalancesView.swift`
- [ ] Calculate net balances per person
- [ ] Build `BalanceDetailView.swift`
- [ ] Show bill-by-bill breakdown

**Task 5.3: Quick Split**
- [ ] Build `QuickSplitView.swift`
- [ ] Equal split calculation
- [ ] Temporary participant support
- [ ] Create bill from quick split

**Task 5.4: Account Settings**
- [ ] Build `AccountView.swift`
- [ ] Profile editing
- [ ] Password change
- [ ] Account deletion
- [ ] Logout functionality

### Phase 6: Advanced Features (3-4 days)

**Task 6.1: Receipt OCR**
- [ ] Integrate Vision framework
- [ ] Build `ReceiptScannerView.swift`
- [ ] Image picker integration
- [ ] Parse receipt text
- [ ] Extract items and prices
- [ ] Batch add to bill

**Task 6.2: Export to Image**
- [ ] Use `ImageRenderer` for SwiftUI snapshot
- [ ] Export summary table as PNG
- [ ] Share sheet integration
- [ ] Save to Photos

**Task 6.3: Offline Support (Optional)**
- [ ] Core Data / SQLite integration
- [ ] Cache bills and contacts locally
- [ ] Sync when online
- [ ] Conflict resolution

### Phase 7: Polish & Testing (2-3 days)

**Task 7.1: UI Polish**
- [ ] Verify all colors match design system
- [ ] Verify all fonts match
- [ ] Verify all spacing matches
- [ ] Add loading states
- [ ] Add empty states
- [ ] Add error states

**Task 7.2: Accessibility**
- [ ] VoiceOver support
- [ ] Dynamic Type support
- [ ] High contrast mode
- [ ] Semantic labels

**Task 7.3: Testing**
- [ ] Unit tests for ViewModels
- [ ] Unit tests for APIClient
- [ ] UI tests for auth flow
- [ ] UI tests for bill creation
- [ ] UI tests for share matrix

**Task 7.4: Performance**
- [ ] Profile app with Instruments
- [ ] Optimize image loading
- [ ] Optimize list rendering
- [ ] Reduce network calls

### Phase 8: Deployment (1-2 days)

**Task 8.1: App Store Prep**
- [ ] Create App Store Connect app
- [ ] Generate screenshots
- [ ] Write app description
- [ ] Set up TestFlight
- [ ] Submit for review

**Task 8.2: CI/CD (Optional)**
- [ ] GitHub Actions for iOS builds
- [ ] Automated TestFlight uploads
- [ ] Version bumping automation

## Estimated Timeline

- **Phase 2**: 2-3 days
- **Phase 3**: 5-7 days
- **Phase 4**: 3-4 days
- **Phase 5**: 4-5 days
- **Phase 6**: 3-4 days
- **Phase 7**: 2-3 days
- **Phase 8**: 1-2 days

**Total**: ~20-28 development days (4-6 weeks calendar time)

## Dependencies

### External Libraries (if needed)
- None required for core functionality
- Consider for advanced features:
  - `Kingfisher` for image caching (if adding profile images)
  - `SwiftLint` for code quality

### Backend Changes
- [ ] Add JWT token generation endpoint for iOS auth
- [ ] CORS configuration for iOS client
- [ ] Rate limiting considerations

## Testing Strategy

### Manual Testing Checklist
- [ ] Login/Register flow
- [ ] Create new bill
- [ ] Add items to bill
- [ ] Edit items
- [ ] Add participants
- [ ] Assign shares (pill UI)
- [ ] Assign shares (matrix UI)
- [ ] Calculate split
- [ ] Export to image
- [ ] View balances
- [ ] Manage contacts
- [ ] Quick split flow
- [ ] Edit account
- [ ] Logout

### Automated Tests
- [ ] API client tests
- [ ] ViewModel tests
- [ ] Calculation logic tests
- [ ] UI flow tests

## Success Criteria

The iOS app is considered feature-complete when:
1. ✅ All core features match web functionality 1:1
2. ✅ Design system is consistently applied
3. ✅ All user flows work end-to-end
4. ✅ No major bugs or crashes
5. ✅ Performance is acceptable (smooth scrolling, quick responses)
6. ✅ Accessible to VoiceOver users
7. ✅ Submitted to TestFlight

## Next Action

👉 **Start with Phase 2, Task 2.1**: Open Xcode and follow `ios/SETUP_INSTRUCTIONS.md` to create the project.

