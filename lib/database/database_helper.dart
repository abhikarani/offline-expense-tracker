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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        isEssential INTEGER NOT NULL DEFAULT 1,
        moneyback REAL NOT NULL DEFAULT 0,
        remarks TEXT NOT NULL DEFAULT '',
        delta REAL NOT NULL,
        net REAL NOT NULL,
        FOREIGN KEY (account) REFERENCES accounts (name)
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        name TEXT PRIMARY KEY,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_account ON transactions(account)');
    await db.execute('CREATE INDEX idx_transactions_tag ON transactions(tag)');

    // Initialize default tags
    await _initializeDefaultTags(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add isEssential column to transactions
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN isEssential INTEGER NOT NULL DEFAULT 1
      ''');

      // Create tags table
      await db.execute('''
        CREATE TABLE tags (
          name TEXT PRIMARY KEY,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Initialize default tags
      await _initializeDefaultTags(db);
    }
  }

  Future _initializeDefaultTags(Database db) async {
    final defaultTags = [
      'Self',
      'Food Vendor',
      'Split Received',
      'Playo',
      'Blinkit',
      'Uber',
      'Swiggy',
    ];

    for (final tagName in defaultTags) {
      await db.insert('tags', {'name': tagName, 'isActive': 1});
    }
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

  /// Add a new account
  Future<void> addAccount(String name, double initialBalance) async {
    final db = await database;
    await db.insert('accounts', {
      'name': name,
      'balance': initialBalance,
    });
  }

  /// Delete an account (only if it has no transactions)
  Future<void> deleteAccount(String name) async {
    final db = await database;
    await db.delete(
      'accounts',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  /// Rename an account (updates both accounts table and all transactions)
  Future<void> renameAccount(String oldName, String newName) async {
    final db = await database;
    await db.transaction((txn) async {
      // Get the old account balance
      final result = await txn.query(
        'accounts',
        where: 'name = ?',
        whereArgs: [oldName],
      );

      if (result.isEmpty) return;

      final balance = result.first['balance'] as double;

      // Delete old account
      await txn.delete(
        'accounts',
        where: 'name = ?',
        whereArgs: [oldName],
      );

      // Insert new account with same balance
      await txn.insert('accounts', {
        'name': newName,
        'balance': balance,
      });

      // Update all transactions with this account
      await txn.update(
        'transactions',
        {'account': newName},
        where: 'account = ?',
        whereArgs: [oldName],
      );
    });
  }

  /// Check if an account has any transactions
  Future<bool> accountHasTransactions(String accountName) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'account = ?',
      whereArgs: [accountName],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ==================== TRANSACTION OPERATIONS ====================

  // ==================== TAG OPERATIONS ====================

  /// Get all active tags
  Future<List<String>> getActiveTags() async {
    final db = await database;
    final result = await db.query(
      'tags',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((row) => row['name'] as String).toList();
  }

  /// Get all tags (including inactive)
  Future<List<String>> getAllTagNames() async {
    final db = await database;
    final result = await db.query('tags', orderBy: 'name ASC');
    return result.map((row) => row['name'] as String).toList();
  }

  /// Add a new tag
  Future<void> addTag(String name) async {
    final db = await database;
    await db.insert('tags', {'name': name, 'isActive': 1});
  }

  /// Delete a tag (soft delete by marking as inactive)
  Future<void> deleteTag(String name) async {
    final db = await database;
    await db.update(
      'tags',
      {'isActive': 0},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  /// Rename a tag (updates both tags table and all transactions)
  Future<void> renameTag(String oldName, String newName) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update tags table
      await txn.delete('tags', where: 'name = ?', whereArgs: [oldName]);
      await txn.insert('tags', {'name': newName, 'isActive': 1});

      // Update all transactions with this tag
      await txn.update(
        'transactions',
        {'tag': newName},
        where: 'tag = ?',
        whereArgs: [oldName],
      );
    });
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
    bool isEssential = true,
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
      isEssential: isEssential,
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
  /// Excludes "Self" tag as it represents transfers, not spending
  Future<Map<String, double>> getSpendingByTag() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT tag, SUM(amount) as total
      FROM transactions
      WHERE type = 'debit' AND tag != 'Self'
      GROUP BY tag
      ORDER BY total DESC
    ''');

    final Map<String, double> spending = {};
    for (var row in result) {
      spending[row['tag'] as String] = row['total'] as double;
    }
    return spending;
  }

  /// Get essential vs non-essential spending
  /// Returns map with 'essential' and 'non-essential' keys
  /// Excludes "Self" tag as it represents transfers, not spending
  Future<Map<String, double>> getEssentialVsNonEssentialSpending() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        CASE WHEN isEssential = 1 THEN 'Essential' ELSE 'Non-Essential' END as category,
        SUM(amount) as total
      FROM transactions
      WHERE type = 'debit' AND tag != 'Self'
      GROUP BY isEssential
    ''');

    final Map<String, double> spending = {'Essential': 0.0, 'Non-Essential': 0.0};
    for (var row in result) {
      spending[row['category'] as String] = row['total'] as double;
    }
    return spending;
  }

  /// Get monthly spending (last 12 months)
  /// Returns map of 'YYYY-MM' -> total debit amount
  /// Excludes "Self" tag as it represents transfers, not spending
  Future<Map<String, double>> getMonthlySpending() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        strftime('%Y-%m', date) as month,
        SUM(amount) as total
      FROM transactions
      WHERE type = 'debit' AND tag != 'Self'
      GROUP BY month
      ORDER BY month DESC
      LIMIT 12
    ''');

    final Map<String, double> spending = {};
    for (var row in result) {
      spending[row['month'] as String] = row['total'] as double;
    }
    return spending;
  }

  /// Get monthly net worth (last 12 months)
  /// Returns map of 'YYYY-MM' -> net worth at end of month
  Future<Map<String, double>> getMonthlyNetWorth() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        strftime('%Y-%m', date) as month,
        MAX(net) as net_at_month_end
      FROM transactions
      GROUP BY month
      ORDER BY month DESC
      LIMIT 12
    ''');

    final Map<String, double> netWorth = {};
    for (var row in result) {
      netWorth[row['month'] as String] = row['net_at_month_end'] as double;
    }
    return netWorth;
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
    bool isEssential = true,
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
        'isEssential': isEssential ? 1 : 0,
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
