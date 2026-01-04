import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'models/transaction.dart';
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
    return ChangeNotifierProvider(
      create: (context) {
        final provider = AppProvider();

        /// Initialize DB + accounts
        provider.initialize().then((_) {
          /// Start listening to notifications AFTER init
          setupNotificationListener(provider);
        });

        return provider;
      },
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
void _parseAndInsert(String text, AppProvider provider) {
  final lower = text.toLowerCase();

  /// Ignore OTPs and promos
  if (lower.contains('otp')) return;

  /// Extract amount (Rs / ₹)
  final amountRegex = RegExp(r'(rs\.?|₹)\s?([\d,]+\.?\d*)');
  final match = amountRegex.firstMatch(lower);
  if (match == null) return;

  final amount =
      double.tryParse(match.group(2)!.replaceAll(',', ''));
  if (amount == null || amount <= 0) return;

  /// Detect debit / credit
  final isDebit = lower.contains('debit');
  final isCredit = lower.contains('credit');

  if (!isDebit && !isCredit) return;

  /// Auto insert transaction with defaults
  provider.addTransaction(
    date: DateTime.now(),
    type: isDebit ? TransactionType.debit : TransactionType.credit,
    amount: amount,
    account: 'Wallet',
    tag: 'NA',
    moneyback: 0,
    remarks: text,
  );
}
