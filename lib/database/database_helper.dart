import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/transaction.dart' as models;


/// Database helper for managing SQLite database
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Accounts table
    await db.execute('''
      CREATE TABLE accounts (
        name TEXT PRIMARY KEY,
        balance REAL NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        account TEXT NOT NULL,
        tag TEXT NOT NULL,
        moneyback REAL NOT NULL DEFAULT 0,
        remarks TEXT NOT NULL DEFAULT '',
        delta REAL NOT NULL,
        net REAL NOT NULL,
        FOREIGN KEY (account) REFERENCES accounts (name)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_account ON transactions(account)');
    await db.execute('CREATE INDEX idx_transactions_tag ON transactions(tag)');
  }

  // ==================== ACCOUNT OPERATIONS ====================

  /// Initialize the 3 fixed accounts with starting balances
  Future<void> initializeAccounts(
    double bankBalance,
    double cashBalance,
    double walletBalance,
  ) async {
    final db = await database;

    await db.insert('accounts', {'name': 'Bank', 'balance': bankBalance});
    await db.insert('accounts', {'name': 'Cash', 'balance': cashBalance});
    await db.insert('accounts', {'name': 'Wallet', 'balance': walletBalance});
  }

  /// Get all accounts
  Future<List<Account>> getAllAccounts() async {
    final db = await database;
    final result = await db.query('accounts', orderBy: 'name ASC');
    return result.map((map) => Account.fromMap(map)).toList();
  }

  /// Get account by name
  Future<Account?> getAccount(String name) async {
    final db = await database;
    final result = await db.query(
      'accounts',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (result.isEmpty) return null;
    return Account.fromMap(result.first);
  }

  /// Update account balance
  Future<void> updateAccountBalance(String name, double newBalance) async {
    final db = await database;
    await db.update(
      'accounts',
      {'balance': newBalance},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  /// Get total net amount (sum of all account balances)
  Future<double> getNetAmount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(balance) as total FROM accounts');
    return (result.first['total'] as double?) ?? 0.0;
  }

  /// Check if accounts have been initialized
  Future<bool> areAccountsInitialized() async {
    final db = await database;
    final result = await db.query('accounts');
    return result.isNotEmpty;
  }

  // ==================== TRANSACTION OPERATIONS ====================

  /// Add a new transaction and update account balance
  /// Returns the created transaction with calculated fields
  Future<models.Transaction> addTransaction({
    required DateTime date,
    required models.TransactionType type,
    required double amount,
    required String account,
    required String tag,
    double moneyback = 0.0,
    String remarks = '',
  }) async {
    final db = await database;

    // Calculate delta based on transaction type
    final delta = type == models.TransactionType.credit ? amount : -amount;

    // Get current account balance
    final currentAccount = await getAccount(account);
    if (currentAccount == null) {
      throw Exception('Account $account not found');
    }

    // Update account balance
    final newBalance = currentAccount.balance + delta;
    await updateAccountBalance(account, newBalance);

    // Calculate net (sum of all account balances)
    final net = await getNetAmount();

    // Create transaction
    final transaction = models.Transaction(
      date: date,
      type: type,
      amount: amount,
      account: account,
      tag: tag,
      moneyback: moneyback,
      remarks: remarks,
      delta: delta,
      net: net,
    );

    // Insert into database
    final id = await db.insert('transactions', transaction.toMap());

    return transaction.copyWith(id: id);
  }

  /// Get all transactions (latest first)
  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Get transaction by ID
  Future<models.Transaction?> getTransaction(int id) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return models.Transaction.fromMap(result.first);
  }

  /// Get transactions filtered by date range
  Future<List<models.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Get transactions filtered by account
  Future<List<models.Transaction>> getTransactionsByAccount(String account) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'account = ?',
      whereArgs: [account],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Get transactions filtered by tag
  Future<List<models.Transaction>> getTransactionsByTag(String tag) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'tag = ?',
      whereArgs: [tag],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Get transactions for today
  Future<List<models.Transaction>> getTodayTransactions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getTransactionsByDateRange(startOfDay, endOfDay);
  }

  /// Get today's total delta (sum of all deltas for today)
  Future<double> getTodayDelta() async {
    final transactions = await getTodayTransactions();
    return transactions.fold<double>(0.0, (sum, t) => sum + t.delta);
  }

  /// Get total "to get back" amount (sum of all moneyback values)
  Future<double> getTotalToGetBack() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(moneyback) as total FROM transactions',
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  /// Get all unique tags
  Future<List<String>> getAllTags() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT tag FROM transactions ORDER BY tag ASC',
    );
    return result.map((row) => row['tag'] as String).toList();
  }

  /// Get spending by tag (for insights)
  /// Returns map of tag -> total debit amount
  Future<Map<String, double>> getSpendingByTag() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT tag, SUM(amount) as total
      FROM transactions
      WHERE type = 'debit'
      GROUP BY tag
      ORDER BY total DESC
    ''');

    final Map<String, double> spending = {};
    for (var row in result) {
      spending[row['tag'] as String] = row['total'] as double;
    }
    return spending;
  }

  /// Get net worth over time (for insights chart)
  /// Returns list of transactions with their net values
  Future<List<models.Transaction>> getNetWorthHistory() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'date ASC, id ASC',
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Delete a transaction and recalculate balances
  /// NOTE: This is complex - you need to revert the balance change
  /// and recalculate all subsequent transactions
  Future<void> deleteTransaction(int id) async {
    final db = await database;

    // Get the transaction to delete
    final transaction = await getTransaction(id);
    if (transaction == null) return;

    // Revert the account balance
    final account = await getAccount(transaction.account);
    if (account != null) {
      final newBalance = account.balance - transaction.delta;
      await updateAccountBalance(transaction.account, newBalance);
    }

    // Delete the transaction
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Note: For simplicity, we're not recalculating net values for all transactions
    // In a production app, you'd want to recalculate net for all transactions after this one
  }
  /// Close database connection
  Future close() async {
    final db = await database;
    await db.close();
  }
  Future<void> updateTransaction({
    required models.Transaction oldTx,
    required DateTime date,
    required models.TransactionType type,
    required double amount,
    required String account,
    required String tag,
    double moneyback = 0,
    String remarks = '',
  }) async {
    final db = await database;

    // 1️⃣ Reverse old transaction
    final reverseDelta =
        oldTx.type == models.TransactionType.debit
            ? oldTx.amount
            : -oldTx.amount;

    await db.rawUpdate(
      '''
      UPDATE accounts
      SET balance = balance + ?
      WHERE name = ?
      ''',
      [reverseDelta, oldTx.account],
    );

    // 2️⃣ Apply new transaction
    final newDelta =
        type == models.TransactionType.debit ? -amount : amount;

    await db.rawUpdate(
      '''
      UPDATE accounts
      SET balance = balance + ?
      WHERE name = ?
      ''',
      [newDelta, account],
    );

    // 3️⃣ Recalculate net
    final net = await getNetAmount();

    // 4️⃣ Update transaction row
    await db.update(
      'transactions',
      {
        'date': date.toIso8601String(),
        'type': type == models.TransactionType.debit ? 'debit' : 'credit',
        'amount': amount,
        'account': account,
        'tag': tag,
        'moneyback': moneyback,
        'remarks': remarks,
        'delta': newDelta,
        'net': net,
      },
      where: 'id = ?',
      whereArgs: [oldTx.id],
    );
  }

}
