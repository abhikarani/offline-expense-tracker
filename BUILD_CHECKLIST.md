# Build & Test Checklist

Use this checklist before building your final APK.

## Pre-Build Checklist

### Environment Setup
- [ ] Flutter installed and in PATH
- [ ] Android SDK installed
- [ ] `flutter doctor` shows all green checkmarks
- [ ] VS Code or Android Studio installed

### Dependencies
- [ ] Run `flutter pub get` successfully
- [ ] No dependency conflicts
- [ ] All packages downloaded

## Development Testing

### Basic Functionality
- [ ] App launches without crashes
- [ ] Initial setup screen shows correctly
- [ ] Can enter starting balances
- [ ] Navigates to home screen after setup
- [ ] Bottom navigation works (Home/History/Insights tabs)

### Transaction Operations
- [ ] Can add a debit transaction
- [ ] Can add a credit transaction
- [ ] Balance updates correctly after debit
- [ ] Balance updates correctly after credit
- [ ] Delta is calculated correctly (negative for debit, positive for credit)
- [ ] Net amount updates correctly
- [ ] Transaction appears in history
- [ ] Tag autocomplete works

### Account Balances
- [ ] Bank balance shows correctly
- [ ] Cash balance shows correctly
- [ ] Wallet balance shows correctly
- [ ] Net = Bank + Cash + Wallet (verify with calculator)

### Moneyback Feature
- [ ] Can add moneyback amount to transaction
- [ ] ToGetBack sum is calculated correctly
- [ ] Moneyback doesn't affect account balance
- [ ] ToGetBack shows on dashboard

### History Screen
- [ ] All transactions appear in history
- [ ] Transactions sorted by date (latest first)
- [ ] Can filter by date range
- [ ] Can filter by account
- [ ] Can filter by tag
- [ ] Multiple filters work together
- [ ] Clear filters button works
- [ ] Transaction details modal shows all info

### Insights Screen
- [ ] Spending by category pie chart loads
- [ ] Pie chart shows correct percentages
- [ ] Net worth line chart loads
- [ ] Line chart shows trend correctly
- [ ] Account distribution shows correct percentages
- [ ] Summary cards show correct values

### Edge Cases
- [ ] Can handle ₹0.00 amount? (might want to prevent)
- [ ] Can handle very large amounts (₹1,000,000+)
- [ ] Can handle decimal amounts (₹99.50)
- [ ] Empty tag validation works
- [ ] Empty amount validation works
- [ ] Can create transaction with same date
- [ ] Pull to refresh works on all screens

### UI/UX
- [ ] All text is readable
- [ ] Colors make sense (red for debit, green for credit)
- [ ] Icons are appropriate
- [ ] Bottom sheet closes properly
- [ ] Back button works on all screens
- [ ] Forms clear after successful save
- [ ] Loading indicators show when needed
- [ ] Success/error messages appear

## Build Process

### Clean Build
```bash
# Step 1: Clean previous builds
flutter clean

# Step 2: Get dependencies
flutter pub get

# Step 3: Analyze code for issues
flutter analyze

# Step 4: Build APK
flutter build apk --release
```

### Build Checklist
- [ ] No errors during build
- [ ] No warnings (or only acceptable warnings)
- [ ] APK file created successfully
- [ ] APK location: `build\app\outputs\flutter-apk\app-release.apk`
- [ ] APK size is reasonable (< 30 MB expected)

### Alternative: Split APKs (for smaller file size)
```bash
flutter build apk --split-per-abi
```
- [ ] Three APKs created:
  - `app-armeabi-v7a-release.apk` (32-bit ARM)
  - `app-arm64-v8a-release.apk` (64-bit ARM) ← Most phones
  - `app-x86_64-release.apk` (x86 64-bit)

## Installation Testing

### Install on Phone
- [ ] APK copied to phone
- [ ] Can locate APK in file manager
- [ ] "Install from Unknown Sources" enabled if needed
- [ ] APK installs without errors
- [ ] App icon appears in app drawer
- [ ] App opens when tapped

### Post-Install Testing
- [ ] App launches on first run
- [ ] Setup screen appears
- [ ] Can complete setup
- [ ] Can add transactions
- [ ] Data persists after closing app
- [ ] Data persists after phone restart
- [ ] App doesn't crash during normal use

### Performance Testing
- [ ] App opens quickly (< 3 seconds)
- [ ] Scrolling is smooth
- [ ] Animations are fluid
- [ ] No lag when adding transactions
- [ ] Charts load reasonably fast
- [ ] No battery drain issues
- [ ] No excessive storage usage

### Stress Testing
- [ ] Add 10+ transactions → still works fine
- [ ] Add 100+ transactions → still works fine
- [ ] Filter with many results → still works fine
- [ ] Switch between tabs rapidly → no crashes
- [ ] Rotate screen → UI adjusts properly

## Final Checks

### App Quality
- [ ] No spelling mistakes in UI
- [ ] All buttons work as expected
- [ ] All forms validate correctly
- [ ] No placeholder text visible
- [ ] No debug messages visible
- [ ] Proper error messages shown

### Data Integrity
- [ ] Calculations are correct (manual verify a few)
- [ ] Database doesn't corrupt after many transactions
- [ ] No data loss after app close/reopen
- [ ] No duplicate transactions created

### User Experience
- [ ] App is intuitive to use
- [ ] Navigation makes sense
- [ ] Colors are pleasant
- [ ] Text is readable
- [ ] Touch targets are big enough
- [ ] Forms are easy to fill

## Distribution Checklist

### Before Sharing APK
- [ ] Tested on at least one real device
- [ ] All critical features work
- [ ] No known crashes
- [ ] APK file is renamed meaningfully (e.g., `expense-tracker-v1.0.apk`)
- [ ] Checksum/hash generated (optional, for verification)

### Share With Users
- [ ] Provide installation instructions
- [ ] Mention minimum Android version (Android 5.0+)
- [ ] Provide usage guide
- [ ] Mention it's offline-only
- [ ] Mention data is not backed up automatically

## Troubleshooting Failed Builds

### If `flutter build apk` fails:

1. **Check Flutter version**
   ```bash
   flutter --version
   flutter upgrade
   ```

2. **Clear everything and rebuild**
   ```bash
   flutter clean
   flutter pub cache repair
   flutter pub get
   flutter build apk
   ```

3. **Check for specific errors**
   - Gradle errors → Update Android Gradle plugin
   - Out of memory → Increase Gradle memory in `android/gradle.properties`
   - Missing SDK → Install required Android SDK version

4. **Build with verbose output**
   ```bash
   flutter build apk --release --verbose
   ```

### If app crashes after install:

1. **Check device logs**
   ```bash
   flutter logs
   ```
   or
   ```bash
   adb logcat
   ```

2. **Build debug APK for better error messages**
   ```bash
   flutter build apk --debug
   ```

3. **Check for permission issues**
   - Storage permissions?
   - Minimum Android version met?

## Version Management

For future updates:

### Increment version in pubspec.yaml
```yaml
version: 1.0.0+1
         ↑     ↑
    Version   Build
```

### Version naming convention:
- **1.0.0** → Initial release
- **1.0.1** → Bug fix
- **1.1.0** → New feature
- **2.0.0** → Major change

### Before releasing new version:
- [ ] Update version in `pubspec.yaml`
- [ ] Test all existing features still work
- [ ] Test new features thoroughly
- [ ] Update README with changes
- [ ] Rename APK with version number

## Sign-Off

Once all items are checked:

- [ ] **Development complete**
- [ ] **Testing complete**
- [ ] **Build successful**
- [ ] **Installation verified**
- [ ] **Ready for use**

**Build Date**: ___________

**Tested By**: ___________

**Device Model**: ___________

**Android Version**: ___________

**Build Type**: [ ] APK [ ] Split APKs

**Notes**:
```
(Any issues or observations during testing)
```

---

**Ready to distribute!** 🚀
