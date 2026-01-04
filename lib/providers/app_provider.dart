import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';

/// Main app state provider
class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // State
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  double _netAmount = 0.0;
  double _todayDelta = 0.0;
  double _totalToGetBack = 0.0;
  bool _isLoading = false;

  // Getters
  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  double get netAmount => _netAmount;
  double get todayDelta => _todayDelta;
  double get totalToGetBack => _totalToGetBack;
  bool get isLoading => _isLoading;

  /// Initialize app data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadAccounts();
      await loadTransactions();
      await loadDashboardData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all accounts
  Future<void> loadAccounts() async {
    _accounts = await _db.getAllAccounts();
    notifyListeners();
  }

  /// Load all transactions
  Future<void> loadTransactions() async {
    _transactions = await _db.getAllTransactions();
    notifyListeners();
  }

  /// Load dashboard data (net, today delta, to get back)
  Future<void> loadDashboardData() async {
    _netAmount = await _db.getNetAmount();
    _todayDelta = await _db.getTodayDelta();
    _totalToGetBack = await _db.getTotalToGetBack();
    notifyListeners();
  }

  /// Initialize accounts with starting balances
  Future<void> initializeAccounts(
    double bankBalance,
    double cashBalance,
    double walletBalance,
  ) async {
    await _db.initializeAccounts(bankBalance, cashBalance, walletBalance);
    await initialize();
  }

  /// Add a new transaction
  Future<void> addTransaction({
    required DateTime date,
    required TransactionType type,
    required double amount,
    required String account,
    required String tag,
    double moneyback = 0.0,
    String remarks = '',
  }) async {
    await _db.addTransaction(
      date: date,
      type: type,
      amount: amount,
      account: account,
      tag: tag,
      moneyback: moneyback,
      remarks: remarks,
    );

    // Reload all data
    await initialize();
  }

  /// Check if accounts are initialized
  Future<bool> areAccountsInitialized() async {
    return await _db.areAccountsInitialized();
  }

  /// Get account by name
  Account? getAccountByName(String name) {
    try {
      return _accounts.firstWhere((a) => a.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await initialize();
  }

  /// Get transactions filtered by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _db.getTransactionsByDateRange(start, end);
  }

  /// Get transactions filtered by account
  Future<List<Transaction>> getTransactionsByAccount(String account) async {
    return await _db.getTransactionsByAccount(account);
  }

  /// Get transactions filtered by tag
  Future<List<Transaction>> getTransactionsByTag(String tag) async {
    return await _db.getTransactionsByTag(tag);
  }

  /// Get spending by tag (for insights)
  Future<Map<String, double>> getSpendingByTag() async {
    return await _db.getSpendingByTag();
  }

  /// Get net worth history (for insights chart)
  Future<List<Transaction>> getNetWorthHistory() async {
    return await _db.getNetWorthHistory();
  }

  /// Get all unique tags
  Future<List<String>> getAllTags() async {
    return await _db.getAllTags();
  }

  /// Update an existing transaction safely
  Future<void> updateTransaction({
    required Transaction oldTransaction,
    required DateTime date,
    required TransactionType type,
    required double amount,
    required String account,
    required String tag,
    double moneyback = 0.0,
    String remarks = '',
  }) async {
    await _db.updateTransaction(
      oldTx: oldTransaction,
      date: date,
      type: type,
      amount: amount,
      account: account,
      tag: tag,
      moneyback: moneyback,
      remarks: remarks,
    );

    // Reload all data to keep UI consistent
    await initialize();
  }
}
