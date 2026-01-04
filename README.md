# Expense Tracker App

A clean, offline-first personal expense tracking app built with Flutter.

## Features

- **3 Fixed Accounts**: Bank, Cash, and Wallet
- **Simple Transaction Management**: Easy debit/credit entry with automatic balance updates
- **Automatic Calculations**: Delta, Net, and ToGetBack calculated automatically
- **Smart Insights**: Pie charts for spending by category, line charts for net worth over time
- **Offline Only**: No cloud sync, no login required - your data stays on your device
- **Clean UI**: Mobile-first design with minimal taps

## Architecture Overview

```
lib/
├── main.dart                   # App entry point and routing
├── models/
│   ├── account.dart           # Account model (Bank, Cash, Wallet)
│   └── transaction.dart       # Transaction model with type enum
├── database/
│   └── database_helper.dart   # SQLite database operations
├── providers/
│   └── app_provider.dart      # State management with Provider
└── screens/
    ├── setup_screen.dart      # Initial account setup
    ├── home_screen.dart       # Dashboard with tabs
    ├── add_transaction_screen.dart  # Transaction form
    ├── history_screen.dart    # Transaction list with filters
    └── insights_screen.dart   # Charts and analytics
```

## How It Works

### Transaction Logic

**Debit Transaction:**
- Selected account balance decreases
- Delta = -amount
- Net = sum of all account balances

**Credit Transaction:**
- Selected account balance increases
- Delta = +amount
- Net = sum of all account balances

### Moneyback & ToGetBack

- **Moneyback**: Amount you expect to receive back (manual input per transaction)
- **ToGetBack**: Cumulative sum of all Moneyback values
- Moneyback does NOT affect account balances
- When money is received, add a manual Credit transaction

### What's Calculated Automatically

- Account balances (based on transactions)
- Delta (per transaction)
- Net amount (sum of all accounts)
- ToGetBack (sum of all moneyback)
- Today's delta

## Setup Instructions

### Prerequisites

1. **Install Flutter**
   - Download from [flutter.dev](https://flutter.dev)
   - Follow installation guide for Windows
   - Add Flutter to your PATH

2. **Verify Installation**
   ```bash
   flutter doctor
   ```
   Make sure Android toolchain is installed and configured.

3. **Install Android Studio** (for Android SDK)
   - Download from [developer.android.com](https://developer.android.com/studio)
   - Install Android SDK and command-line tools

### Project Setup

1. **Navigate to project directory**
   ```bash
   cd d:\study\expenseTracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify everything is set up**
   ```bash
   flutter doctor -v
   ```

## Running the App

### Run on Emulator

1. **Start Android Emulator** (from Android Studio or command line)
   ```bash
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

### Run on Physical Device (USB Debugging)

1. **Enable Developer Options** on your Android phone:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings > Developer Options
   - Enable "USB Debugging"

2. **Connect phone via USB**

3. **Verify device is connected**
   ```bash
   flutter devices
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Building APK for Installation

### Option 1: Build APK (Recommended for Testing)

Build a universal APK that works on all Android devices:

```bash
flutter build apk
```

The APK will be located at:
```
build\app\outputs\flutter-apk\app-release.apk
```

### Option 2: Build Split APKs (Smaller file size)

Build separate APKs for different CPU architectures:

```bash
flutter build apk --split-per-abi
```

This creates three APKs in `build\app\outputs\flutter-apk\`:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM - most modern phones)
- `app-x86_64-release.apk` (x86 64-bit)

Choose the one that matches your phone's architecture (usually arm64-v8a).

### Installing APK on Your Phone

#### Method 1: Direct Transfer

1. Copy the APK file from `build\app\outputs\flutter-apk\app-release.apk` to your phone
2. On your phone, open the file manager
3. Navigate to the APK file
4. Tap to install
5. You may need to allow "Install from Unknown Sources" in Settings

#### Method 2: ADB Install (Recommended)

1. Connect phone via USB with USB Debugging enabled
2. Run:
   ```bash
   flutter install
   ```
   OR
   ```bash
   adb install build\app\outputs\flutter-apk\app-release.apk
   ```

#### Method 3: Using Flutter

The easiest way:
```bash
flutter build apk
flutter install
```

## Database Schema

### Accounts Table
```sql
CREATE TABLE accounts (
  name TEXT PRIMARY KEY,      -- 'Bank', 'Cash', or 'Wallet'
  balance REAL NOT NULL
);
```

### Transactions Table
```sql
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  type TEXT NOT NULL,         -- 'debit' or 'credit'
  amount REAL NOT NULL,
  account TEXT NOT NULL,      -- Foreign key to accounts(name)
  tag TEXT NOT NULL,
  moneyback REAL NOT NULL DEFAULT 0,
  remarks TEXT NOT NULL DEFAULT '',
  delta REAL NOT NULL,        -- Calculated: +/- amount
  net REAL NOT NULL,          -- Calculated: sum of all balances
  FOREIGN KEY (account) REFERENCES accounts (name)
);
```

## Dependencies

- **sqflite**: SQLite database for local storage
- **provider**: State management
- **fl_chart**: Beautiful charts for insights
- **intl**: Date and number formatting

## Troubleshooting

### "flutter: command not found"
- Make sure Flutter is added to your PATH
- Restart your terminal/command prompt

### "No devices found"
- For emulator: Make sure Android emulator is running
- For physical device: Enable USB debugging and accept connection

### "Gradle build failed"
- Run `flutter clean`
- Run `flutter pub get`
- Try again

### APK won't install
- Enable "Install from Unknown Sources" in Android settings
- Check if you have enough storage space
- Make sure you're using the correct APK for your device architecture

### App crashes on startup
- Run `flutter clean`
- Delete the app from your phone
- Rebuild and reinstall

## Future Enhancements (Not Implemented)

- **Notification Parsing**: Read transactions from bank SMS/notifications
  - Would require notification listener permissions
  - Complex and bank-specific parsing
  - Can be added as a future feature

- **Backup/Restore**: Export database to file
- **Categories Management**: Custom tags/categories
- **Budget Planning**: Set monthly budgets per category
- **Reports**: Monthly/yearly expense reports
- **Multi-currency**: Support for multiple currencies

## Notes

- This app stores all data locally using SQLite
- No internet connection required
- No user account or login
- Data is not synced to cloud
- Uninstalling the app will delete all data
- Simple and focused on core expense tracking

## License

Personal project - free to use and modify.
