import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'models/transaction.dart';
import 'models/notification_preferences.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';

/// MethodChannel for Android notification listener
const MethodChannel _notificationChannel =
    MethodChannel('expense_tracker/notifications');

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final provider = AppProvider();

            /// Initialize DB + accounts
            provider.initialize().then((_) {
              /// Start listening to notifications AFTER init
              setupNotificationListener(provider);
            });

            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            home: const InitialScreen(),
            routes: {
              '/setup': (context) => const SetupScreen(),
              '/home': (context) => const HomeScreen(),
              '/add-transaction': (context) => const AddTransactionScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Initial screen that checks if accounts are initialized
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    final provider = context.read<AppProvider>();
    final isInitialized = await provider.areAccountsInitialized();

    if (!mounted) return;

    if (isInitialized) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// ------------------------------------------------------------
/// Notification Listener Setup
/// ------------------------------------------------------------
void setupNotificationListener(AppProvider provider) {
  _notificationChannel.setMethodCallHandler((call) async {
    if (call.method != 'onNotification') return;

    final text = call.arguments as String;
    _parseAndInsert(text, provider);
  });
}

/// ------------------------------------------------------------
/// Notification Parsing Logic
/// ------------------------------------------------------------
void _parseAndInsert(String text, AppProvider provider) async {
  final lower = text.toLowerCase();

  /// Ignore OTPs, promos, and other non-transaction messages
  if (_shouldIgnoreNotification(lower)) return;

  /// Extract amount using multiple patterns
  final amount = _extractAmount(text);
  if (amount == null || amount <= 0) return;

  /// Detect debit / credit
  final isDebit = _isDebitTransaction(lower);
  final isCredit = _isCreditTransaction(lower);

  if (!isDebit && !isCredit) return;

  /// Load user preferences
  final prefs = await NotificationPreferences.load();

  /// Determine account (use preference or auto-detect)
  final account = prefs.useAccountAutoDetection
      ? _detectAccount(lower)
      : (prefs.defaultAccount ?? 'Bank'); // Fallback to Bank if no default set

  /// Determine tag (use preference or auto-detect)
  final tag = prefs.useTagAutoDetection
      ? _detectTag(lower)
      : (prefs.defaultTag ?? 'Self'); // Fallback to Self if no default set

  /// Use essential preference
  final isEssential = prefs.defaultIsEssential;

  /// Auto insert transaction
  provider.addTransaction(
    date: DateTime.now(),
    type: isDebit ? TransactionType.debit : TransactionType.credit,
    amount: amount,
    account: account,
    tag: tag,
    isEssential: isEssential,
    moneyback: 0,
    remarks: text,
  );
}

/// Check if notification should be ignored
bool _shouldIgnoreNotification(String lower) {
  final ignorePatterns = [
    'otp',
    'one time password',
    'verification code',
    'verify',
    'promo',
    'offer',
    'discount code',
    'promotional',
    'advertisement',
    'ad:',
    'balance enquiry',
    'mini statement',
    'statement generated',
  ];

  for (final pattern in ignorePatterns) {
    if (lower.contains(pattern)) return true;
  }

  return false;
}

/// Extract amount from notification using multiple patterns
double? _extractAmount(String text) {
  final lower = text.toLowerCase();

  /// Multiple regex patterns for different bank formats
  final patterns = [
    // Pattern 1: Rs. 1000 or Rs.1000 or Rs 1000
    RegExp(r'rs\.?\s?([\d,]+\.?\d*)', caseSensitive: false),
    // Pattern 2: ₹ 1000 or ₹1000
    RegExp(r'₹\s?([\d,]+\.?\d*)'),
    // Pattern 3: INR 1000 or INR1000
    RegExp(r'inr\s?([\d,]+\.?\d*)', caseSensitive: false),
    // Pattern 4: Amount: 1000 or Amount 1000
    RegExp(r'amount:?\s?([\d,]+\.?\d*)', caseSensitive: false),
    // Pattern 5: Debited/Credited for 1000
    RegExp(r'(?:debited|credited)\s+(?:for|by|of|with)\s+(?:rs\.?|₹|inr)?\s?([\d,]+\.?\d*)', caseSensitive: false),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(lower);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      final amount = double.tryParse(amountStr ?? '');
      if (amount != null && amount > 0) {
        return amount;
      }
    }
  }

  return null;
}

/// Detect if transaction is a debit
bool _isDebitTransaction(String lower) {
  final debitKeywords = [
    'debited',
    'debit',
    'paid',
    'spent',
    'withdrawn',
    'purchase',
    'sent to',
    'transferred to',
    'payment',
  ];

  for (final keyword in debitKeywords) {
    if (lower.contains(keyword)) return true;
  }

  return false;
}

/// Detect if transaction is a credit
bool _isCreditTransaction(String lower) {
  final creditKeywords = [
    'credited',
    'credit',
    'received',
    'deposited',
    'refund',
    'cashback',
    'received from',
  ];

  for (final keyword in creditKeywords) {
    if (lower.contains(keyword)) return true;
  }

  return false;
}

/// Detect account from notification
String _detectAccount(String lower) {
  // Check for UPI or wallet keywords
  if (lower.contains('upi') ||
      lower.contains('paytm') ||
      lower.contains('phonepe') ||
      lower.contains('gpay') ||
      lower.contains('google pay') ||
      lower.contains('bhim') ||
      lower.contains('wallet')) {
    return 'Wallet';
  }

  // Check for bank keywords
  if (lower.contains('a/c') ||
      lower.contains('account') ||
      lower.contains('card') ||
      lower.contains('bank')) {
    return 'Bank';
  }

  // Check for ATM withdrawal
  if (lower.contains('atm') || lower.contains('cash withdrawal')) {
    return 'Cash'; // Withdrawn to cash
  }

  // Default to Bank
  return 'Bank';
}

/// Detect tag from notification based on merchant/service
String _detectTag(String lower) {
  // Check for specific merchants/services
  if (lower.contains('swiggy')) return 'Swiggy';
  if (lower.contains('zomato')) return 'Swiggy'; // Use Swiggy tag for food delivery
  if (lower.contains('uber')) return 'Uber';
  if (lower.contains('ola')) return 'Uber'; // Use Uber tag for ride services
  if (lower.contains('blinkit') || lower.contains('grofers')) return 'Blinkit';
  if (lower.contains('bigbasket') || lower.contains('instamart')) return 'Blinkit';
  if (lower.contains('playo')) return 'Playo';
  if (lower.contains('dunzo')) return 'Blinkit';

  // Check for food-related keywords
  if (lower.contains('restaurant') ||
      lower.contains('cafe') ||
      lower.contains('food') ||
      lower.contains('dining') ||
      lower.contains('meal')) {
    return 'Food Vendor';
  }

  // Check for money received from others
  if (lower.contains('received from') ||
      lower.contains('credited by') ||
      lower.contains('sent by')) {
    return 'Split Received';
  }

  // Check if it's a self transfer
  if (lower.contains('self') ||
      lower.contains('own account') ||
      lower.contains('your account')) {
    return 'Self';
  }

  // Default to Self
  return 'Self';
}
