# iOS App - Quick Start

## 🚀 Get Running in 5 Minutes

### Step 1: Open Xcode Project (30 seconds)
```bash
open /Users/upadhd02/Downloads/Random/Bill_splitter/RestaurantSplit/ios/RestaurantSplit.xcodeproj
```

### Step 2: Delete Auto-Generated Files (30 seconds)

In Xcode Project Navigator:
1. Find `RestaurantSplitApp.swift` (the old one Xcode created)
2. Right-click → Delete → Move to Trash
3. Find `ContentView.swift` (the old one)
4. Right-click → Delete → Move to Trash

### Step 3: Add All New Files (2 minutes)

1. In Xcode, right-click project name in navigator
2. Choose "Add Files to RestaurantSplit..."
3. Navigate to: `/Users/upadhd02/Downloads/Random/Bill_splitter/RestaurantSplit/ios/RestaurantSplit/`
4. Select EVERYTHING (⌘A):
   - `RestaurantSplitApp.swift`
   - `ContentView.swift`
   - `Models` folder
   - `Services` folder
   - `ViewModels` folder
   - `Views` folder
   - `Theme` folder
5. Check ✅ "Copy items if needed"
6. Check ✅ "Create groups"
7. Click "Add"

### Step 4: Add Logo (1 minute)

1. In Project Navigator, open `Assets.xcassets`
2. Right-click in assets → New Image Set
3. Name it: `Logo`
4. Drag `/Users/upadhd02/Downloads/Random/Bill_splitter/RestaurantSplit/packages/ui-assets/restaurantsplit-high-resolution-logo.png` into the 1x slot

### Step 5: Configure Networking (1 minute)

1. Click project name in navigator
2. Select "RestaurantSplit" target
3. Go to "Info" tab
4. Click + to add new key
5. Type: `App Transport Security Settings`
6. Expand it, click + to add sub-key
7. Type: `Allow Arbitrary Loads`
8. Set value to: `YES`

### Step 6: Start Backend (30 seconds)

In Terminal:
```bash
cd /Users/upadhd02/Downloads/Random/Bill_splitter/RestaurantSplit/web
pnpm dev
```

Wait for "Ready in XXXms"

### Step 7: Build & Run (30 seconds)

1. In Xcode, select "iPhone 15 Pro" simulator (or any iOS 17+ device)
2. Press ⌘R (or click Play button)
3. Wait for build...
4. App launches! 🎉

### Step 8: Test

1. **Login screen appears**
   - Email: `abhishekkumar020797@gmail.com`
   - Password: `password123`
   - Click eye icon to verify password
   - Tap "Log in"

2. **Bills tab**
   - Should see your existing bills
   - Tap any bill

3. **Bill detail**
   - See items
   - Try "Add Item"
   - Toggle between "Per item" and "Table" view
   - Test share assignment
   - Tap "Calculate split"

## ⚡ That's It!

You now have a working iOS app matching your web app! 

## 🐛 If Something Goes Wrong

### Build Fails
- Check Issues navigator (⌘5)
- Common fix: Select each Swift file → File Inspector → Check "RestaurantSplit" under Target Membership

### Login Fails
- Verify backend is running at http://localhost:3000
- Check Xcode console for error messages
- Try registering a new account instead

### Bills Don't Load
- Check Xcode console for API errors
- Verify backend has data: `cd web && sqlite3 prisma/dev.db "SELECT COUNT(*) FROM Bill;"`
- Check Info.plist has App Transport Security configured

## 📚 For More Details

- `INTEGRATION_GUIDE.md` - Detailed integration steps
- `CHECKLIST.md` - Complete checklist
- `BUILD_STATUS.md` - What's implemented
- `IMPLEMENTATION_ROADMAP.md` - Full feature roadmap

## 🎯 Success Criteria

✅ App builds without errors
✅ Login screen appears
✅ Can authenticate
✅ Bills list loads
✅ Bill detail shows items
✅ Can assign shares (both UI modes)
✅ Calculation works

If all above work → **Proof of concept complete!** 🎉

