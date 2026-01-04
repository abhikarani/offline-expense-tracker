# Architecture & Implementation Details

## Core Concepts

### 1. Fixed Accounts System

The app uses exactly 3 accounts that are initialized once:
- **Bank**: For bank account balance
- **Cash**: For physical cash
- **Wallet**: For digital wallet/UPI balance

These accounts are created during initial setup and never deleted.

### 2. Transaction Flow

```
User creates transaction
    ↓
Calculate delta (+/- amount based on type)
    ↓
Update account balance (balance += delta)
    ↓
Calculate net (sum of all account balances)
    ↓
Store transaction with calculated fields
    ↓
Update UI automatically via Provider
```

### 3. Balance Calculation Logic

Located in: `lib/database/database_helper.dart`

```dart
// For DEBIT transaction:
delta = -amount
newBalance = currentBalance + delta  // Decreases balance

// For CREDIT transaction:
delta = +amount
newBalance = currentBalance + delta  // Increases balance

// Net is always:
net = bankBalance + cashBalance + walletBalance
```

**Key Point**: User NEVER manually enters balances. All balances are calculated automatically based on:
1. Initial setup values
2. All subsequent transactions

### 4. Moneyback System

**Moneyback** is completely separate from balance calculations:

```dart
// When adding transaction with moneyback:
1. Update account balance normally (based on delta)
2. Store moneyback value separately
3. Calculate ToGetBack = sum of ALL moneyback values

// Important:
- Moneyback does NOT affect account balances
- It's just a tracking field
- When money is actually received, user adds a separate CREDIT transaction
```

**Example Scenario**:
```
Day 1: Pay for dinner ₹1000 (split with friend)
  - Type: Debit
  - Amount: ₹1000
  - Account: Cash
  - Moneyback: ₹500 (friend owes you)
  - Result: Cash balance decreases by ₹1000
  - ToGetBack: ₹500

Day 3: Friend pays you back
  - Type: Credit
  - Amount: ₹500
  - Account: Cash
  - Moneyback: 0
  - Result: Cash balance increases by ₹500
  - ToGetBack: Still ₹500 (moneyback from first transaction)
```

## State Management

### Provider Pattern (lib/providers/app_provider.dart)

```
AppProvider (ChangeNotifier)
    ↓
Manages all app state:
- List of accounts
- List of transactions
- Net amount
- Today's delta
- Total to get back
    ↓
Notifies UI on changes
    ↓
UI rebuilds automatically
```

**Key Methods**:

```dart
// Initialize app (called on startup and after changes)
Future<void> initialize() async {
  await loadAccounts();
  await loadTransactions();
  await loadDashboardData();
  notifyListeners(); // Triggers UI rebuild
}

// Add transaction
Future<void> addTransaction(...) async {
  await _db.addTransaction(...);  // Write to database
  await initialize();              // Reload everything
}
```

## Database Layer

### SQLite with sqflite Package

**Why SQLite?**
- Offline-first requirement
- Fast queries
- Relational data (accounts ↔ transactions)
- Mature Flutter support

**Database Operations** (lib/database/database_helper.dart):

1. **Singleton Pattern**: One database instance for the app
```dart
static final DatabaseHelper instance = DatabaseHelper._init();
```

2. **Transaction Creation** (Most important method):
```dart
Future<Transaction> addTransaction({...}) async {
  // 1. Calculate delta
  final delta = type == TransactionType.credit ? amount : -amount;

  // 2. Get current account
  final currentAccount = await getAccount(account);

  // 3. Update account balance
  final newBalance = currentAccount.balance + delta;
  await updateAccountBalance(account, newBalance);

  // 4. Calculate net (sum of all accounts)
  final net = await getNetAmount();

  // 5. Create and insert transaction
  final transaction = Transaction(
    date: date,
    type: type,
    amount: amount,
    account: account,
    tag: tag,
    moneyback: moneyback,
    remarks: remarks,
    delta: delta,  // ← Calculated
    net: net,      // ← Calculated
  );

  final id = await db.insert('transactions', transaction.toMap());
  return transaction.copyWith(id: id);
}
```

3. **Indexes for Performance**:
```sql
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_account ON transactions(account);
CREATE INDEX idx_transactions_tag ON transactions(tag);
```

## UI Screens

### 1. Setup Screen (lib/screens/setup_screen.dart)

**Purpose**: One-time initialization of account balances

**Flow**:
```
App launch
    ↓
Check if accounts exist
    ↓
If NO → Show SetupScreen
    ↓
User enters Bank/Cash/Wallet balances
    ↓
Save to database
    ↓
Navigate to HomeScreen
```

### 2. Home Screen (lib/screens/home_screen.dart)

**Structure**:
```
Scaffold
├── AppBar
├── IndexedStack (for tabs)
│   ├── Dashboard (index 0)
│   ├── HistoryScreen (index 1)
│   └── InsightsScreen (index 2)
├── BottomNavigationBar
└── FloatingActionButton (Add transaction)
```

**Dashboard Shows**:
- Net Amount (big blue card)
- Account balances (Bank, Cash, Wallet)
- Today's delta
- ToGetBack amount
- Recent 5 transactions

**Key Widget**: Uses `Consumer<AppProvider>` to rebuild when data changes

### 3. Add Transaction Screen (lib/screens/add_transaction_screen.dart)

**Form Fields**:
```
Date picker       → Default: today
Type toggle       → Debit / Credit (SegmentedButton)
Amount           → Required, numeric, autofocus
Account dropdown → Bank / Cash / Wallet
Tag              → Required, with autocomplete
Moneyback        → Optional, numeric
Remarks          → Optional, multiline
```

**Features**:
- Tag autocomplete from previous transactions
- Input validation
- Amount formatting (₹ symbol, 2 decimal places)
- Info card showing which balance will change

### 4. History Screen (lib/screens/history_screen.dart)

**Filters**:
```
Date Range → Pick start and end date
Account    → Filter by Bank/Cash/Wallet
Tag        → Filter by category
```

**Filter Logic**:
```dart
// Apply multiple filters in sequence
if (dateRange) → filter by date
if (account) → filter by account
if (tag) → filter by tag

// All filters work together (AND logic)
```

**Transaction Card Shows**:
- Tag name
- Date
- Amount (red for debit, green for credit)
- Account
- Delta
- Net at that transaction
- Moneyback indicator (if > 0)

**Tap behavior**: Show full transaction details in bottom sheet

### 5. Insights Screen (lib/screens/insights_screen.dart)

**Charts**:

1. **Spending by Category (Pie Chart)**:
```dart
// Get spending data
Map<String, double> spending = await getSpendingByTag();
// Groups all DEBIT transactions by tag
// Shows percentage distribution

// Uses fl_chart package
PieChart(
  sections: spending.map((tag, amount) =>
    PieChartSectionData(
      value: amount,
      title: '${percentage}%',
      color: colors[index],
    )
  )
)
```

2. **Net Worth Over Time (Line Chart)**:
```dart
// Get all transactions ordered by date
List<Transaction> history = await getNetWorthHistory();

// Plot points: (transaction index, net value at that point)
// Shows how net worth changed over time

LineChart(
  lineBarsData: [
    LineChartBarData(
      spots: history.map((t, index) => FlSpot(index, t.net)),
      isCurved: true,
    )
  ]
)
```

3. **Account Distribution**:
- Shows each account's percentage of total net worth
- Linear progress bars
- Real-time calculation

## Key Design Decisions

### 1. Why No Cloud Sync?

**Reasons**:
- Simpler codebase (no auth, no API, no sync conflicts)
- Faster (no network calls)
- More private (data never leaves device)
- Offline-first guarantee
- Lower complexity for single-user app

**Trade-off**: Can't access data from multiple devices

### 2. Why Provider over Riverpod/Bloc?

**Reasons**:
- Simpler for small app
- Less boilerplate
- Built-in with Flutter
- Easy to understand
- Sufficient for this use case

**Trade-off**: Less powerful for complex state scenarios

### 3. Why Calculate and Store Delta/Net?

**Option A** (Current): Calculate once, store in database
```dart
// Pros:
- Fast queries (no calculation needed)
- Easy filtering/sorting
- Historical accuracy preserved

// Cons:
- Slight data redundancy
- Delete operation needs balance recalculation
```

**Option B**: Calculate on-the-fly
```dart
// Pros:
- No redundancy
- Always accurate

// Cons:
- Slower (calculate every time)
- Complex queries
- Can't easily show "net at that point in time"
```

**Decision**: Option A is better for this app because:
- We show historical net values (what was net worth at that transaction)
- Performance matters for list scrolling
- Deletes are rare

### 4. Fixed Accounts vs. User-Defined

**Current**: 3 fixed accounts (Bank, Cash, Wallet)

**Pros**:
- Simpler UI (dropdown instead of management screen)
- Covers 95% of use cases
- No "account management" complexity
- Easier to understand

**Cons**:
- Can't add custom accounts
- Can't delete/rename accounts

**Decision**: Fixed accounts for v1, can add custom accounts later if needed

## Data Flow Examples

### Example 1: Adding a Debit Transaction

```
User fills form:
  Date: Jan 1, 2024
  Type: Debit
  Amount: 500
  Account: Cash
  Tag: Food

User taps Save
    ↓
AddTransactionScreen._saveTransaction()
    ↓
AppProvider.addTransaction()
    ↓
DatabaseHelper.addTransaction()
    ↓
Calculate delta = -500
    ↓
Get current Cash account (balance: 5000)
    ↓
Update Cash balance = 5000 + (-500) = 4500
    ↓
Calculate net = Bank + Cash + Wallet = 10000 + 4500 + 2000 = 16500
    ↓
Insert transaction into database with:
  - delta: -500
  - net: 16500
    ↓
Return to AppProvider
    ↓
AppProvider.initialize() (reload all data)
    ↓
notifyListeners() → UI rebuilds
    ↓
User sees:
  - Cash balance: 4500 (decreased)
  - Net amount: 16500 (decreased)
  - New transaction in history
```

### Example 2: Viewing Insights

```
User taps Insights tab
    ↓
InsightsScreen builds
    ↓
FutureBuilder calls provider.getSpendingByTag()
    ↓
DatabaseHelper.getSpendingByTag()
    ↓
SQL query:
  SELECT tag, SUM(amount) as total
  FROM transactions
  WHERE type = 'debit'
  GROUP BY tag
    ↓
Returns: {
  'Food': 5000,
  'Transport': 2000,
  'Shopping': 3000
}
    ↓
Pie chart renders with:
  - Food: 50% (blue)
  - Shopping: 30% (red)
  - Transport: 20% (green)
```

## Error Handling

### Database Errors
```dart
try {
  await _db.addTransaction(...);
} catch (e) {
  // Show error to user via SnackBar
  ScaffoldMessenger.show(
    SnackBar(content: Text('Error: $e'))
  );
}
```

### Validation Errors
```dart
// Form validation happens BEFORE database operations
if (!_formKey.currentState!.validate()) {
  return; // Don't proceed
}
```

### State Errors
```dart
// Always check if widget is still mounted before setState
if (mounted) {
  setState(() { ... });
}
```

## Performance Optimizations

### 1. Indexes
- Created on commonly queried fields (date, account, tag)
- Speeds up filtering operations

### 2. Lazy Loading
- FutureBuilder loads data only when needed
- Charts load independently

### 3. IndexedStack
- Keeps all tabs in memory (fast switching)
- Trade-off: Slightly more memory usage
- Worth it for smooth UX

### 4. Provider Updates
- Only notify listeners when data actually changes
- Prevents unnecessary rebuilds

## Testing Strategy (Not Implemented, but Recommended)

### Unit Tests
```dart
test('Delta calculation for debit', () {
  expect(calculateDelta(TransactionType.debit, 100), -100);
});

test('Delta calculation for credit', () {
  expect(calculateDelta(TransactionType.credit, 100), 100);
});
```

### Widget Tests
```dart
testWidgets('Add transaction form validation', (tester) async {
  await tester.pumpWidget(AddTransactionScreen());
  await tester.tap(find.text('Save'));
  expect(find.text('Please enter amount'), findsOneWidget);
});
```

### Integration Tests
```dart
testWidgets('Complete transaction flow', (tester) async {
  // 1. Start app
  // 2. Setup accounts
  // 3. Add transaction
  // 4. Verify balance changed
  // 5. Verify transaction appears in history
});
```

## Future Enhancement Ideas

### 1. Notification Parsing
```dart
// Would require:
- NotificationListenerService permission
- SMS READ permission
- Bank-specific parsers
- Regex patterns for each bank

// Complexity: HIGH
// Value: HIGH (automation)
```

### 2. Recurring Transactions
```dart
// Features:
- Set transaction to repeat (daily/weekly/monthly)
- Auto-create on schedule
- Notification reminders

// Complexity: MEDIUM
// Value: MEDIUM
```

### 3. Budget Tracking
```dart
// Features:
- Set monthly budget per category
- Show spending vs budget
- Alerts when approaching limit

// Complexity: MEDIUM
// Value: HIGH
```

### 4. Data Export/Backup
```dart
// Features:
- Export database to JSON/CSV
- Import from backup
- Cloud backup option

// Complexity: LOW
// Value: HIGH (data safety)
```

### 5. Multi-Currency
```dart
// Features:
- Support multiple currencies
- Exchange rate tracking
- Convert between currencies

// Complexity: HIGH
// Value: MEDIUM (niche use case)
```

## Assumptions Made

1. **Single user**: No multi-user support needed
2. **Rupee only**: Only ₹ (INR) currency
3. **No categories**: Tags are freeform text, not predefined categories
4. **No budgets**: Just tracking, no planning features
5. **No recurring**: Each transaction is one-time
6. **No attachments**: No photos or receipts
7. **No search**: Filters are sufficient
8. **No backup**: User responsible for data (could add later)
9. **Modern Android**: Targets Android 5.0+ (API level 21+)
10. **No web/iOS**: Android-only for now

## Code Quality Notes

### Clean Code Practices
- ✅ Single Responsibility Principle (each class has one job)
- ✅ Clear naming (e.g., `getTotalToGetBack()` is self-documenting)
- ✅ Comments explain "why", not "what"
- ✅ No magic numbers (constants are named)
- ✅ Error handling at appropriate levels

### Separation of Concerns
```
Models       → Data structures only
Database     → All SQL operations
Providers    → Business logic & state
Screens      → UI only, minimal logic
```

### No Unnecessary Abstractions
- Direct database calls (no repository pattern)
- Simple Provider (no complex state machines)
- Inline widgets where appropriate (not everything needs extraction)

This keeps the code maintainable without over-engineering.
