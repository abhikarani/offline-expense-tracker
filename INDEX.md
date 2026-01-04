# Expense Tracker - Documentation Index

## 📚 Quick Navigation

Welcome to the Expense Tracker app documentation. Use this index to find what you need quickly.

---

## 🚀 Getting Started (Start Here!)

**New to this project? Start in this order:**

1. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** ⭐ START HERE
   - High-level overview of the entire project
   - What was built and why
   - Complete file structure
   - 5-minute project understanding

2. **[QUICKSTART.md](QUICKSTART.md)** ⭐ THEN THIS
   - Get app running in 5 minutes
   - Step-by-step setup instructions
   - Common commands
   - First-time user guide

3. **[README.md](README.md)**
   - Complete feature list
   - Architecture overview
   - Build instructions
   - Database schema
   - All dependencies

---

## 📖 Documentation Files

### Core Documentation

| File | Purpose | When to Read |
|------|---------|--------------|
| **[README.md](README.md)** | Complete project documentation | When you need comprehensive info |
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | High-level project overview | First thing to read |
| **[QUICKSTART.md](QUICKSTART.md)** | 5-minute setup guide | When setting up for first time |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Technical deep dive | When you want to understand how it works |

### Visual & Reference

| File | Purpose | When to Read |
|------|---------|--------------|
| **[SCREENS_OVERVIEW.md](SCREENS_OVERVIEW.md)** | Visual mockups of all screens | When you want to see UI layout |
| **[BUILD_CHECKLIST.md](BUILD_CHECKLIST.md)** | Pre-release testing checklist | Before building final APK |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Solutions to common issues | When something goes wrong |
| **[INDEX.md](INDEX.md)** | This file - navigation guide | When you're lost |

---

## 💻 Code Files

### Application Entry
- **[lib/main.dart](lib/main.dart)** - App initialization, routing, theme

### Data Models
- **[lib/models/account.dart](lib/models/account.dart)** - Account data structure
- **[lib/models/transaction.dart](lib/models/transaction.dart)** - Transaction model with enum

### Database Layer
- **[lib/database/database_helper.dart](lib/database/database_helper.dart)** - SQLite operations (~500 lines)
  - Account CRUD
  - Transaction CRUD
  - Balance calculations
  - Filtering & aggregations

### State Management
- **[lib/providers/app_provider.dart](lib/providers/app_provider.dart)** - Provider pattern state management

### UI Screens
- **[lib/screens/setup_screen.dart](lib/screens/setup_screen.dart)** - Initial account setup
- **[lib/screens/home_screen.dart](lib/screens/home_screen.dart)** - Main dashboard with tabs
- **[lib/screens/add_transaction_screen.dart](lib/screens/add_transaction_screen.dart)** - Transaction form
- **[lib/screens/history_screen.dart](lib/screens/history_screen.dart)** - Transaction list + filters
- **[lib/screens/insights_screen.dart](lib/screens/insights_screen.dart)** - Charts and analytics

### Configuration
- **[pubspec.yaml](pubspec.yaml)** - Dependencies and app metadata
- **[.gitignore](.gitignore)** - Git ignore rules

---

## 📋 Documentation by Purpose

### I want to...

#### 🏃 Get Started Quickly
→ Read: [QUICKSTART.md](QUICKSTART.md)
- 5-minute setup
- Common commands
- Quick troubleshooting

#### 📱 Understand What Was Built
→ Read: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
- Feature list
- High-level overview
- Design decisions

#### 🎨 See the UI Design
→ Read: [SCREENS_OVERVIEW.md](SCREENS_OVERVIEW.md)
- Screen mockups
- User flow diagrams
- Color scheme
- Typography

#### 🔧 Understand the Code
→ Read: [ARCHITECTURE.md](ARCHITECTURE.md)
- Code structure
- Design patterns
- Calculation logic
- Database operations

#### 🏗️ Build the APK
→ Read: [README.md](README.md#building-apk-for-installation)
- Build commands
- APK location
- Installation methods

#### 🧪 Test Before Release
→ Read: [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md)
- Pre-build checklist
- Testing scenarios
- Quality assurance

#### 🐛 Fix an Issue
→ Read: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Common errors
- Solutions
- Debug tips

#### 📚 Learn Everything
→ Read in order:
1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
2. [README.md](README.md)
3. [ARCHITECTURE.md](ARCHITECTURE.md)
4. [SCREENS_OVERVIEW.md](SCREENS_OVERVIEW.md)

---

## 🎯 Quick Reference

### Essential Commands

```bash
# Setup
flutter pub get

# Run on device/emulator
flutter run

# Build APK
flutter build apk --release

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Clean project
flutter clean

# Check setup
flutter doctor
```

### File Locations

**APK after build**:
```
build\app\outputs\flutter-apk\app-release.apk
```

**Database file on device**:
```
/data/data/com.example.expense_tracker/databases/expense_tracker.db
```

**Main code directory**:
```
lib/
```

### Key Concepts

**3 Fixed Accounts**:
- Bank
- Cash
- Wallet

**Transaction Types**:
- Debit (decreases balance)
- Credit (increases balance)

**Calculated Fields** (never entered manually):
- Delta (± amount)
- Net (sum of all accounts)
- ToGetBack (sum of moneyback)

**Formula**:
```
Delta = type == credit ? +amount : -amount
New Balance = Old Balance + Delta
Net = Bank + Cash + Wallet
ToGetBack = SUM(moneyback)
```

---

## 🔍 Search by Topic

### Database
- Schema: [README.md](README.md#database-schema)
- Operations: [ARCHITECTURE.md](ARCHITECTURE.md#database-layer)
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md#database-issues)

### Screens
- Overview: [SCREENS_OVERVIEW.md](SCREENS_OVERVIEW.md)
- Implementation: Files in `lib/screens/`
- Navigation: [ARCHITECTURE.md](ARCHITECTURE.md#ui-screens)

### Calculations
- Logic: [ARCHITECTURE.md](ARCHITECTURE.md#critical-calculation-logic)
- Examples: [ARCHITECTURE.md](ARCHITECTURE.md#data-flow-examples)
- Verification: [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md#balance-calculations-wrong)

### Building & Deployment
- Build guide: [README.md](README.md#building-apk-for-installation)
- Quick build: [QUICKSTART.md](QUICKSTART.md#step-6-build-apk-for-manual-installation)
- Testing: [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md)
- Issues: [TROUBLESHOOTING.md](TROUBLESHOOTING.md#build-issues)

### Features
- Complete list: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md#-core-features-implemented)
- How they work: [ARCHITECTURE.md](ARCHITECTURE.md)
- UI design: [SCREENS_OVERVIEW.md](SCREENS_OVERVIEW.md)

---

## 📊 Project Statistics

- **Total Dart Files**: 12
- **Total Lines of Code**: ~2,250
- **Screens**: 5
- **Models**: 2
- **Database Tables**: 2
- **Documentation Files**: 8
- **Dependencies**: 6 packages

---

## 🎓 Learning Path

### Beginner (Just Starting)
1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Understand what's built
2. [QUICKSTART.md](QUICKSTART.md) - Get it running
3. [SCREENS_OVERVIEW.md](SCREENS_OVERVIEW.md) - See the UI
4. Play with the app!

### Intermediate (Want to Modify)
1. [README.md](README.md) - Full documentation
2. [ARCHITECTURE.md](ARCHITECTURE.md) - How it works
3. [lib/](lib/) - Read the code
4. Make small changes and test

### Advanced (Deep Understanding)
1. [ARCHITECTURE.md](ARCHITECTURE.md) - All technical details
2. [database_helper.dart](lib/database/database_helper.dart) - Study database code
3. [app_provider.dart](lib/providers/app_provider.dart) - Study state management
4. Implement new features

---

## 🛠️ Common Tasks

### First Time Setup
```
1. Read: QUICKSTART.md
2. Run: flutter pub get
3. Run: flutter doctor
4. Run: flutter run
```

### Add New Feature
```
1. Read: ARCHITECTURE.md (understand current structure)
2. Plan: Where does it fit?
3. Code: Implement in appropriate file
4. Test: flutter run
5. Document: Update relevant .md files
```

### Fix a Bug
```
1. Reproduce: What's the exact error?
2. Read: TROUBLESHOOTING.md
3. Debug: flutter run --verbose
4. Check logs: flutter logs
5. Fix and test
```

### Release New Version
```
1. Complete: BUILD_CHECKLIST.md
2. Update: version in pubspec.yaml
3. Build: flutter build apk --release
4. Test: Install on real device
5. Distribute: Share APK file
```

---

## 💡 Tips

### For Developers
- Always read [ARCHITECTURE.md](ARCHITECTURE.md) before modifying code
- Use [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md) before releases
- Keep [TROUBLESHOOTING.md](TROUBLESHOOTING.md) handy

### For Users
- Start with [QUICKSTART.md](QUICKSTART.md)
- Refer to [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if issues arise
- See [SCREENS_OVERVIEW.md](SCREENS_OVERVIEW.md) to understand the UI

### For Project Managers
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) has complete overview
- [README.md](README.md) has all features and specs
- [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md) for QA process

---

## 📞 Need Help?

### Can't find something?
- Use Ctrl+F in individual files
- Check this index
- Read [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### App won't build?
→ [TROUBLESHOOTING.md](TROUBLESHOOTING.md#build-issues)

### App won't run?
→ [TROUBLESHOOTING.md](TROUBLESHOOTING.md#runtime-issues)

### Don't understand the code?
→ [ARCHITECTURE.md](ARCHITECTURE.md)

### Need to modify something?
→ [ARCHITECTURE.md](ARCHITECTURE.md) + relevant code file

---

## 📝 Document Versions

All documentation is for:
- **App Version**: 1.0.0
- **Flutter SDK**: 3.x.x
- **Date**: January 2024

---

## ✅ Next Steps

**Complete beginner?**
→ [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

**Want to run the app?**
→ [QUICKSTART.md](QUICKSTART.md)

**Want to understand everything?**
→ [README.md](README.md)

**Want to build APK?**
→ [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md)

**Having issues?**
→ [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Happy coding! 🚀**
