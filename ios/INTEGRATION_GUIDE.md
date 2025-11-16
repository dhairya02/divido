# iOS App Integration Guide

## Files Created

I've generated all the core Swift files for your iOS app. Here's how to add them to your Xcode project:

## Step 1: Add All Files to Xcode

1. Open your `RestaurantSplit.xcodeproj` in Xcode
2. In Project Navigator, right-click on the project root
3. Select "Add Files to RestaurantSplit..."
4. Navigate to `/Users/upadhd02/Downloads/Random/Bill_splitter/RestaurantSplit/ios/RestaurantSplit/`
5. Select ALL the folders and files
6. **Important**: Check "Copy items if needed" and "Create groups"
7. Click "Add"

## Step 2: Verify File Structure

Your Project Navigator should now show:

```
RestaurantSplit/
├── RestaurantSplitApp.swift
├── ContentView.swift
├── Models/
│   ├── User.swift
│   ├── Contact.swift
│   ├── Bill.swift
│   ├── Calculation.swift
│   └── Auth.swift
├── Services/
│   ├── APIClient.swift
│   └── KeychainService.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── BillsViewModel.swift
│   └── BillDetailViewModel.swift
├── Views/
│   ├── Authentication/
│   │   ├── LoginView.swift
│   │   └── RegisterView.swift
│   ├── Bills/
│   │   ├── BillsListView.swift
│   │   ├── BillDetailView.swift
│   │   ├── NewBillView.swift
│   │   ├── ItemShareEditorView.swift
│   │   └── ItemShareMatrixView.swift
│   ├── Contacts/
│   │   └── ContactsListView.swift
│   ├── Balances/
│   │   └── BalancesView.swift
│   ├── Account/
│   │   └── AccountView.swift
│   └── Components/
│       ├── CustomButton.swift
│       ├── CustomTextField.swift
│       └── MoneyText.swift
└── Theme/
    └── Theme.swift
```

## Step 3: Configure Assets

### Add Logo Image

1. In Xcode, open `Assets.xcassets`
2. Right-click → New Image Set → Name it "Logo"
3. Drag `packages/ui-assets/restaurantsplit-high-resolution-logo.png` into all three slots (1x, 2x, 3x)

### Add Color Assets

1. In `Assets.xcassets`, create a new folder called "Colors"
2. Add these Color Sets:
   - **Primary**: #6F8BFF
   - **PrimaryAccent**: #E6FDA3
   - **Success**: #065F46
   - **Error**: #DC2626

For each color:
- Right-click Colors folder → New Color Set
- Name it (e.g., "Primary")
- In Attributes Inspector, set "Any Appearance" to the hex value

## Step 4: Add EB Garamond Font (Optional but Recommended)

1. Download EB Garamond from [Google Fonts](https://fonts.google.com/specimen/EB+Garamond)
2. Add these font files to your project:
   - `EBGaramond-Regular.ttf`
   - `EBGaramond-Medium.ttf`
   - `EBGaramond-Bold.ttf`
3. Make sure "Target Membership" is checked
4. Open `Info.plist` (or add to Info tab in target settings):
   - Add key: "Fonts provided by application" (UIAppFonts)
   - Add items:
     - `EBGaramond-Regular.ttf`
     - `EBGaramond-Medium.ttf`
     - `EBGaramond-Bold.ttf`

**Note**: If you skip fonts, the app will use system font which is also fine.

## Step 5: Configure Info.plist

Add these keys to support networking in development:

1. Open Info.plist
2. Add key: `App Transport Security Settings` (Dictionary)
3. Inside it, add: `Allow Arbitrary Loads` (Boolean) = `YES`

**⚠️ Warning**: For production, configure proper TLS and remove this setting!

## Step 6: Build & Run

1. Select a simulator (iPhone 15 Pro recommended)
2. Press **⌘R** or click the Play button
3. Wait for build to complete

## Expected Build Issues & Fixes

### Issue: "Cannot find type 'X' in scope"
**Fix**: Make sure all files are added to the target. Check Target Membership in File Inspector.

### Issue: Font not loading
**Fix**: 
- Verify fonts are in project with target membership
- Check Info.plist has correct font filenames
- Clean build folder (⌘⇧K) and rebuild

### Issue: "Module 'X' not found"
**Fix**: All code uses only Foundation and SwiftUI - no external dependencies needed.

### Issue: Network requests failing
**Fix**:
- Make sure web backend is running: `cd web && pnpm dev`
- Check Info.plist has App Transport Security configured
- Update `APIClient.swift` baseURL if using different port

## Step 7: Test the App

### Test Authentication
1. Launch app - should show Login screen
2. Try logging in with:
   - Email: `abhishekkumar020797@gmail.com`
   - Password: `password123`
3. Should navigate to Bills tab

### Test Bills
1. Tap "Bills" tab
2. Should see list of bills from your database
3. Tap a bill to see details
4. Try adding an item
5. Test the share editor

### Test Share Matrix
1. In bill detail, toggle to "Table" view
2. Scroll horizontally and vertically
3. Headers should stay visible
4. Tap cells to highlight rows/columns

## Current Feature Status

✅ **Implemented:**
- Login/Register with password toggle (matching web)
- Bills list with pull-to-refresh
- Bill detail view
- Add items
- Item share editor (pill-based UI)
- Item share matrix (table view with sticky headers)
- Basic navigation and tabs
- Logout

⏳ **Not Yet Implemented (use placeholders):**
- Contacts CRUD
- Balances calculation
- Quick Split
- Full Account settings
- Receipt OCR
- Export to image

## Next Steps for Full Implementation

See `IMPLEMENTATION_ROADMAP.md` for the complete feature roadmap.

For now, you can:
1. Test the core bill splitting workflow
2. Verify design matches web version
3. Identify any issues or missing features
4. Continue with Phase 5-8 implementation

## Troubleshooting

### App crashes on launch
- Check console for errors
- Verify all files compile without errors
- Try cleaning and rebuilding

### Can't see any bills
- Verify backend is running
- Check network configuration
- Look for API errors in Xcode console

### Login doesn't work
- Backend authentication is still using NextAuth (web-based)
- iOS app uses basic auth as placeholder
- For production, implement JWT token endpoint

## Production Checklist

Before releasing:
- [ ] Remove App Transport Security exception
- [ ] Implement proper JWT authentication
- [ ] Add proper error handling UI
- [ ] Implement all remaining features
- [ ] Add comprehensive testing
- [ ] Configure proper backend URL
- [ ] Add app icon
- [ ] Add launch screen
- [ ] Test on physical devices

