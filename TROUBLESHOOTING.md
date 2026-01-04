# Troubleshooting Guide

Common issues and their solutions when building and running the Expense Tracker app.

## Table of Contents
- [Installation Issues](#installation-issues)
- [Build Issues](#build-issues)
- [Runtime Issues](#runtime-issues)
- [Database Issues](#database-issues)
- [APK Installation Issues](#apk-installation-issues)
- [UI/Display Issues](#ui-display-issues)

---

## Installation Issues

### ❌ "flutter: command not found"

**Cause**: Flutter is not in your system PATH

**Solution**:
1. Open System Properties → Environment Variables
2. Edit "Path" variable
3. Add Flutter bin directory: `C:\flutter\bin`
4. Restart terminal/VS Code
5. Verify: `flutter --version`

### ❌ "Unable to locate Android SDK"

**Cause**: Android SDK not installed or not found

**Solution**:
1. Install Android Studio OR Android Command-line Tools
2. Set ANDROID_HOME environment variable:
   ```
   ANDROID_HOME=C:\Users\YourName\AppData\Local\Android\Sdk
   ```
3. Add to PATH:
   ```
   %ANDROID_HOME%\platform-tools
   %ANDROID_HOME%\tools
   ```
4. Run `flutter doctor --android-licenses`
5. Accept all licenses

### ❌ "cmdline-tools component is missing"

**Cause**: Android command-line tools not installed

**Solution**:
1. Open Android Studio
2. Go to Tools → SDK Manager
3. Select "SDK Tools" tab
4. Check "Android SDK Command-line Tools"
5. Click Apply

OR via command line:
```bash
sdkmanager "cmdline-tools;latest"
```

---

## Build Issues

### ❌ "Gradle build failed"

**Cause**: Various Gradle issues

**Solution 1** - Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter build apk
```

**Solution 2** - Clear Gradle cache:
```bash
cd android
gradlew clean
cd ..
flutter build apk
```

**Solution 3** - Update Gradle (if very old):
Edit `android/gradle/wrapper/gradle-wrapper.properties`:
```
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5-all.zip
```

### ❌ "Out of memory" during build

**Cause**: Insufficient memory for Gradle

**Solution**:
Edit `android/gradle.properties`, add:
```
org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
```

### ❌ "Execution failed for task ':app:lintVitalRelease'"

**Cause**: Lint errors in release build

**Solution**:
Edit `android/app/build.gradle`, add inside `android` block:
```gradle
lintOptions {
    checkReleaseBuilds false
    abortOnError false
}
```

### ❌ "Could not find com.android.tools.build:gradle:X.X.X"

**Cause**: Gradle plugin version mismatch

**Solution**:
Edit `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:7.3.1'  // Use stable version
}
```

### ❌ "Package name not found" or "AndroidManifest.xml missing"

**Cause**: Corrupted Flutter project structure

**Solution**:
```bash
flutter create --org com.yourname expensetracker_new
# Copy lib/ folder to new project
# Copy pubspec.yaml dependencies
flutter pub get
flutter build apk
```

### ❌ Dependency version conflicts

**Cause**: Incompatible package versions

**Solution**:
```bash
flutter pub upgrade --major-versions
flutter pub get
```

Or manually specify compatible versions in `pubspec.yaml`.

---

## Runtime Issues

### ❌ App crashes immediately on launch

**Cause 1**: Database initialization error

**Solution**:
- Uninstall app completely from phone
- Clear app data
- Rebuild and reinstall:
  ```bash
  flutter clean
  flutter build apk
  adb install -r build/app/outputs/flutter-apk/app-release.apk
  ```

**Cause 2**: Missing permissions

**Solution**:
Check `android/app/src/main/AndroidManifest.xml` has:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### ❌ "MissingPluginException"

**Cause**: Plugin not registered

**Solution**:
```bash
flutter clean
flutter pub get
flutter build apk
```

### ❌ White screen on launch

**Cause**: Loading issue or initialization error

**Solution**:
1. Check logs:
   ```bash
   adb logcat | findstr "flutter"
   ```
2. Look for error messages
3. Common fix:
   ```bash
   flutter clean
   flutter pub get
   flutter run --release
   ```

### ❌ Transactions not saving

**Cause**: Database write error

**Solution**:
1. Check device logs for SQLite errors
2. Clear app data and restart
3. Verify form validation is passing
4. Check database helper code for errors

**Debug**:
```dart
// Add try-catch in database_helper.dart
try {
  await db.insert('transactions', transaction.toMap());
} catch (e) {
  print('Database insert error: $e');
  rethrow;
}
```

### ❌ Balance calculations wrong

**Cause**: Logic error in delta calculation

**Verification**:
1. Check delta = -amount for debit, +amount for credit
2. Verify newBalance = oldBalance + delta
3. Check net = sum of all three accounts
4. Look at database values directly:
   ```bash
   adb shell
   cd /data/data/com.example.expense_tracker/databases
   sqlite3 expense_tracker.db
   SELECT * FROM accounts;
   SELECT * FROM transactions ORDER BY id DESC LIMIT 5;
   .exit
   ```

---

## Database Issues

### ❌ "database is locked" error

**Cause**: Multiple simultaneous database operations

**Solution**:
Ensure DatabaseHelper uses singleton pattern:
```dart
static final DatabaseHelper instance = DatabaseHelper._init();
```

Always use same instance:
```dart
final db = DatabaseHelper.instance;
```

### ❌ Data lost after app update

**Cause**: Database recreation on schema change

**Prevention**:
When updating schema, implement migration:
```dart
Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add migration SQL here
  }
}

openDatabase(
  path,
  version: 2,  // Increment version
  onCreate: _createDB,
  onUpgrade: _onUpgrade,
);
```

### ❌ Duplicate data after reinstall

**Cause**: Database not deleted on uninstall

**Solution**:
Uninstall app completely:
```bash
adb uninstall com.example.expense_tracker
```

Then reinstall.

### ❌ "no such table" error

**Cause**: Database not initialized or corrupted

**Solution**:
1. Clear app data
2. Uninstall and reinstall
3. Check onCreate is being called
4. Verify table creation SQL syntax

---

## APK Installation Issues

### ❌ "App not installed" error

**Cause 1**: Insufficient storage

**Solution**: Free up space on phone

**Cause 2**: Conflicting package

**Solution**: Uninstall old version first
```bash
adb uninstall com.example.expense_tracker
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Cause 3**: Corrupt APK

**Solution**: Rebuild
```bash
flutter clean
flutter build apk
```

### ❌ "Installation blocked" warning

**Cause**: Security settings

**Solution**:
1. Go to Settings → Security
2. Enable "Unknown Sources" or "Install Unknown Apps"
3. Allow installation from File Manager

### ❌ "Parse error: There is a problem parsing the package"

**Cause**: APK built for wrong architecture or corrupt

**Solution**:
Build universal APK:
```bash
flutter build apk --release
```

Or build for specific architecture:
```bash
flutter build apk --split-per-abi
```
Install the correct one (usually arm64-v8a).

### ❌ Can't find APK file after build

**Location**:
```
d:\study\expenseTracker\build\app\outputs\flutter-apk\app-release.apk
```

If missing, build failed. Check console output for errors.

---

## UI/Display Issues

### ❌ Charts not showing

**Cause**: No data or fl_chart dependency issue

**Solution**:
1. Verify you have transactions in database
2. Check fl_chart is in pubspec.yaml
3. Rebuild:
   ```bash
   flutter pub get
   flutter clean
   flutter build apk
   ```

### ❌ Text overflowing or cut off

**Cause**: Long text without wrapping

**Solution**:
Wrap text widgets with Expanded or Flexible:
```dart
Expanded(
  child: Text(
    longText,
    overflow: TextOverflow.ellipsis,
  ),
)
```

### ❌ Layout broken on different screen sizes

**Cause**: Fixed sizes instead of responsive

**Solution**:
Use MediaQuery and flexible widgets:
```dart
width: MediaQuery.of(context).size.width * 0.9
```

### ❌ Dark mode issues (future consideration)

**Current**: App uses light theme only

**To add dark mode**:
In main.dart:
```dart
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system,
  ...
)
```

### ❌ Currency symbol not showing (₹)

**Cause**: Font doesn't support rupee symbol

**Solution**: Already using default font which supports ₹

If issue persists, explicitly set:
```dart
NumberFormat.currency(symbol: '₹', locale: 'en_IN')
```

---

## Device-Specific Issues

### ❌ App works on emulator but not on phone

**Possible causes**:
1. Different Android versions
2. Different architectures
3. Permissions not granted on phone

**Solution**:
1. Check minimum SDK version in `android/app/build.gradle`:
   ```gradle
   minSdkVersion 21  // Android 5.0+
   ```
2. Build release APK and test:
   ```bash
   flutter build apk --release
   ```
3. Check phone Android version is supported

### ❌ USB debugging not working

**Solution**:
1. Enable Developer Options:
   - Settings → About Phone
   - Tap Build Number 7 times
2. Enable USB Debugging:
   - Settings → Developer Options
   - Turn on USB Debugging
3. Authorize computer:
   - Tap "Allow" on phone popup
   - Check "Always allow from this computer"
4. Verify:
   ```bash
   adb devices
   ```

---

## Performance Issues

### ❌ App is slow/laggy

**Possible causes**:
1. Too many transactions in database
2. Inefficient queries
3. Large image assets

**Solutions**:
1. Add pagination to history screen
2. Optimize database queries with indexes (already added)
3. Use const constructors where possible
4. Profile app:
   ```bash
   flutter run --profile
   ```

### ❌ App takes long to start

**Cause**: Database initialization or large data load

**Solution**:
- Show loading indicator while initializing
- Load data incrementally
- Use FutureBuilder for async operations

---

## Development Issues

### ❌ Hot reload not working

**Solution**:
1. Try hot restart: Press `R` in terminal
2. If that doesn't work:
   ```bash
   flutter clean
   flutter run
   ```

### ❌ "Unable to find valid certification path"

**Cause**: Network/SSL issue with pub.dev

**Solution**:
1. Check internet connection
2. Try different network (not corporate network)
3. Or temporarily disable SSL verification (not recommended):
   ```bash
   flutter pub get --insecure
   ```

### ❌ VS Code Flutter extension not working

**Solution**:
1. Restart VS Code
2. Run "Flutter: Run Flutter Doctor" from Command Palette
3. Reinstall Flutter extension
4. Check Flutter SDK path in settings

---

## Common Error Messages

### "A RenderFlex overflowed by X pixels"

**Cause**: Widget too large for available space

**Solution**: Wrap with SingleChildScrollView or use Expanded

### "setState() called after dispose()"

**Cause**: Async operation completing after navigation

**Solution**:
```dart
if (mounted) {
  setState(() { ... });
}
```

### "Null check operator used on a null value"

**Cause**: Trying to access null value with !

**Solution**: Use null-aware operators:
```dart
value?.property
value ?? defaultValue
```

### "Bad state: No element"

**Cause**: List is empty when calling .first or similar

**Solution**:
```dart
// Instead of:
list.first

// Use:
list.isNotEmpty ? list.first : defaultValue
// or
list.firstWhere((e) => condition, orElse: () => defaultValue)
```

---

## Getting Help

### Debug Mode

Run in debug mode for detailed errors:
```bash
flutter run --debug
```

### Check Logs

**On Windows**:
```bash
flutter logs
```

**Or with ADB**:
```bash
adb logcat | findstr "flutter"
```

### Enable Verbose Output

```bash
flutter run --verbose
flutter build apk --verbose
```

### Flutter Doctor

Always start with:
```bash
flutter doctor -v
```

This shows detailed info about your Flutter setup.

### Generate Crash Reports

If app crashes, check:
```bash
adb logcat *:E
```
(Shows only errors)

### Clean Everything

Nuclear option - clean everything and rebuild:
```bash
flutter clean
flutter pub cache repair
flutter pub get
flutter build apk
```

---

## Still Having Issues?

1. **Check Flutter version**: `flutter --version`
   - Upgrade if old: `flutter upgrade`

2. **Check Dart version**: Should match Flutter

3. **Check Android SDK**: `flutter doctor`

4. **Search error message**: Google the exact error

5. **Check GitHub Issues**: Flutter or package-specific

6. **Stack Overflow**: Search for similar problems

7. **Re-read docs**:
   - [README.md](README.md)
   - [QUICKSTART.md](QUICKSTART.md)
   - [ARCHITECTURE.md](ARCHITECTURE.md)

---

## Prevention Tips

### Before Building:
1. Run `flutter doctor`
2. Run `flutter analyze`
3. Test on emulator first
4. Then test on real device
5. Clear and rebuild before release

### During Development:
1. Commit code frequently
2. Test after each feature
3. Keep dependencies updated
4. Use version control (Git)

### Best Practices:
1. Always use `flutter clean` before final build
2. Test APK on real device before distributing
3. Keep notes of what works
4. Document any custom changes

---

**Most issues can be resolved with:**
```bash
flutter clean
flutter pub get
flutter build apk
```

**And uninstall/reinstall the app on your device.**
