import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'history_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

/// Home/Dashboard screen showing net amount, balances, and today's delta
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          const HistoryScreen(),
          const InsightsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed('/add-transaction');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }

  Widget _buildDashboard() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => provider.initialize(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Notification Settings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        tooltip: themeProvider.isDarkMode
                            ? 'Switch to Light Mode'
                            : 'Switch to Dark Mode',
                        onPressed: () => themeProvider.toggleTheme(),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Expense Tracker'),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Net Amount Card
                    _buildNetAmountCard(provider.netAmount),
                    const SizedBox(height: 16),

                    // Account Balances
                    _buildAccountBalances(provider.accounts),
                    const SizedBox(height: 16),

                    // Today's Delta and ToGetBack
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            title: 'Today',
                            value: provider.todayDelta,
                            icon: Icons.today,
                            color: provider.todayDelta >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            title: 'To Get Back',
                            value: provider.totalToGetBack,
                            icon: Icons.payments,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 1; // Switch to History tab
                            });
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Recent Transactions List
                    ...provider.transactions.take(5).map((transaction) {
                      return _buildTransactionTile(transaction);
                    }).toList(),

                    if (provider.transactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNetAmountCard(double netAmount) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[700]!,
              Colors.blue[500]!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Net Amount',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '₹').format(netAmount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountBalances(List<Account> accounts) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...accounts.map((account) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(
                      _getAccountIcon(account.name),
                      color: _getAccountColor(account.name),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        account.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '₹').format(account.balance),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '₹').format(value.abs()),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(transaction) {
    final isDebit = transaction.type == TransactionType.debit;
    final color = isDebit ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isDebit ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.tag,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${transaction.account} • ${DateFormat('MMM dd').format(transaction.date)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDebit ? '-' : '+'}${NumberFormat.currency(symbol: '₹').format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              'Δ ${NumberFormat.currency(symbol: '₹').format(transaction.delta)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          _showTransactionDetails(transaction);
        },
      ),
    );
  }

  void _showTransactionDetails(transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(transaction.date)),
              _buildDetailRow('Type', transaction.type.displayName),
              _buildDetailRow('Amount', NumberFormat.currency(symbol: '₹').format(transaction.amount)),
              _buildDetailRow('Account', transaction.account),
              _buildDetailRow('Tag', transaction.tag),
              _buildDetailRow('Delta', NumberFormat.currency(symbol: '₹').format(transaction.delta)),
              _buildDetailRow('Net', NumberFormat.currency(symbol: '₹').format(transaction.net)),
              if (transaction.moneyback > 0)
                _buildDetailRow('Moneyback', NumberFormat.currency(symbol: '₹').format(transaction.moneyback)),
              if (transaction.remarks.isNotEmpty)
                _buildDetailRow('Remarks', transaction.remarks),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAccountIcon(String accountName) {
    switch (accountName) {
      case 'Bank':
        return Icons.account_balance;
      case 'Cash':
        return Icons.money;
      case 'Wallet':
        return Icons.wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getAccountColor(String accountName) {
    switch (accountName) {
      case 'Bank':
        return Colors.blue;
      case 'Cash':
        return Colors.green;
      case 'Wallet':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
