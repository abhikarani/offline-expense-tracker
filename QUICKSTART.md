# Quick Start Guide

## Get Your App Running in 5 Minutes

### Step 1: Install Flutter (if not already installed)

1. Download Flutter SDK from [flutter.dev](https://docs.flutter.dev/get-started/install/windows)
2. Extract to `C:\flutter` (or any location without spaces)
3. Add to PATH: `C:\flutter\bin`
4. Restart your terminal/VS Code

### Step 2: Install Android Requirements

Option A - **Android Studio** (Easiest):
1. Download from [developer.android.com/studio](https://developer.android.com/studio)
2. Install with default settings
3. Open Android Studio → More Actions → SDK Manager
4. Install Android SDK (API 33 or higher)
5. Install Android SDK Command-line Tools

Option B - **Command Line Tools** (Lighter):
1. Download command-line tools from [developer.android.com](https://developer.android.com/studio#command-line-tools-only)
2. Extract and run sdkmanager to install required packages

### Step 3: Verify Setup

Open Command Prompt or PowerShell:

```bash
flutter doctor
```

You should see:
```
✓ Flutter (Channel stable, 3.x.x)
✓ Android toolchain - develop for Android devices
✓ Android Studio (or Command-line tools)
```

If you see ✗ for any item, follow the instructions shown.

### Step 4: Get Dependencies

In your project directory:

```bash
cd d:\study\expenseTracker
flutter pub get
```

This downloads all required packages (sqflite, provider, fl_chart, etc.)

### Step 5: Run the App

#### Option A: Using Android Emulator

1. Create an emulator (if you don't have one):
   ```bash
   flutter emulators --create --name pixel
   ```

2. Launch it:
   ```bash
   flutter emulators --launch pixel
   ```

3. Run the app:
   ```bash
   flutter run
   ```

#### Option B: Using Your Phone (Recommended for APK testing)

1. Enable Developer Mode on your Android phone:
   - Go to **Settings** → **About Phone**
   - Tap **Build Number** 7 times
   - You'll see "You are now a developer!"

2. Enable USB Debugging:
   - Go to **Settings** → **System** → **Developer Options**
   - Turn on **USB Debugging**

3. Connect phone to PC via USB

4. Check if detected:
   ```bash
   flutter devices
   ```
   You should see your phone listed.

5. Run the app:
   ```bash
   flutter run
   ```

The app will install and launch on your phone automatically!

### Step 6: Build APK for Manual Installation

To create an APK file you can share or install later:

```bash
flutter build apk --release
```

**Find your APK at:**
```
d:\study\expenseTracker\build\app\outputs\flutter-apk\app-release.apk
```

**Install it:**
- Copy `app-release.apk` to your phone
- Open file manager on phone
- Tap the APK file
- Allow "Install from Unknown Sources" if prompted
- Tap Install

Done! 🎉

## Common Issues & Fixes

### "flutter: command not found"
**Solution**: Add Flutter to PATH and restart terminal
```
System Properties → Environment Variables → Path → Add → C:\flutter\bin
```

### "No connected devices"
**Solution for emulator**:
```bash
flutter emulators
flutter emulators --launch <emulator_name>
```

**Solution for phone**:
- Check USB cable (use data cable, not just charging cable)
- On phone: Tap "Allow USB Debugging" popup
- Try `adb devices` to verify connection

### "Gradle build failed"
**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

### "Could not find Java"
**Solution**: Install JDK 11 or higher
- Download from [Oracle](https://www.oracle.com/java/technologies/downloads/) or [OpenJDK](https://adoptium.net/)
- Set JAVA_HOME environment variable

### App installed but won't open
**Solution**:
- Uninstall the app from phone
- Run `flutter clean`
- Rebuild: `flutter build apk --release`
- Reinstall

## What's Next?

### First Time Setup
When you first open the app:
1. Enter starting balances for Bank, Cash, and Wallet
2. Tap "Get Started"

### Add Your First Transaction
1. Tap the **+ Add** button
2. Enter amount (e.g., 500)
3. Select Debit or Credit
4. Choose account (Bank/Cash/Wallet)
5. Enter tag (e.g., "Food", "Transport")
6. Optionally add moneyback amount
7. Tap **Save**

### View Insights
1. Go to **Insights** tab
2. See spending breakdown by category
3. View net worth over time

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models
│   ├── account.dart
│   └── transaction.dart
├── database/                      # Database layer
│   └── database_helper.dart
├── providers/                     # State management
│   └── app_provider.dart
└── screens/                       # UI screens
    ├── setup_screen.dart         # Initial setup
    ├── home_screen.dart          # Main dashboard
    ├── add_transaction_screen.dart
    ├── history_screen.dart
    └── insights_screen.dart
```

## Need Help?

- **Full Documentation**: See [README.md](README.md)
- **Architecture Details**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **Flutter Docs**: [docs.flutter.dev](https://docs.flutter.dev)
- **Flutter Issue**: Run `flutter doctor -v` for detailed diagnostics

## Development Tips

### Hot Reload (While app is running)
Press `r` in terminal → Reloads UI instantly without restarting app

### Hot Restart
Press `R` in terminal → Restarts app from beginning

### View Logs
Press `l` in terminal → Shows detailed logs

### Open DevTools
Press `d` in terminal → Opens Flutter DevTools in browser

### Quit
Press `q` in terminal → Stops the app

### VS Code Extension (Recommended)
Install "Flutter" extension in VS Code for:
- Auto-completion
- Code snippets
- Debugging
- Widget inspector

Happy coding! 🚀
