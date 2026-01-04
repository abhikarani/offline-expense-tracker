import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';

/// Transaction history screen with filters
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _selectedAccount;
  String? _selectedTag;
  DateTimeRange? _selectedDateRange;
  List<Transaction> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  Future<void> _applyFilters() async {
    final provider = context.read<AppProvider>();
    List<Transaction> transactions;

    // Apply filters in order
    if (_selectedDateRange != null) {
      transactions = await provider.getTransactionsByDateRange(
        _selectedDateRange!.start,
        _selectedDateRange!.end,
      );
    } else if (_selectedAccount != null) {
      transactions = await provider.getTransactionsByAccount(_selectedAccount!);
    } else if (_selectedTag != null) {
      transactions = await provider.getTransactionsByTag(_selectedTag!);
    } else {
      transactions = provider.transactions;
    }

    // Apply additional filters if multiple are selected
    if (_selectedAccount != null && _selectedDateRange != null) {
      transactions =
          transactions.where((t) => t.account == _selectedAccount).toList();
    }

    if (_selectedTag != null &&
        (_selectedDateRange != null || _selectedAccount != null)) {
      transactions = transactions.where((t) => t.tag == _selectedTag).toList();
    }

    setState(() {
      _filteredTransactions = transactions;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedAccount = null;
      _selectedTag = null;
      _selectedDateRange = null;
    });
    _applyFilters();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final transactions = _selectedAccount != null ||
                _selectedTag != null ||
                _selectedDateRange != null
            ? _filteredTransactions
            : provider.transactions;

        return Column(
          children: [
            // Filter chips
            _buildFilterSection(provider),

            // Transaction list
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        await provider.initialize();
                        _applyFilters();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterSection(AppProvider provider) {
    final hasFilters = _selectedAccount != null ||
        _selectedTag != null ||
        _selectedDateRange != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date range filter
                FilterChip(
                  label: Text(
                    _selectedDateRange == null
                        ? 'Date Range'
                        : '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                  ),
                  selected: _selectedDateRange != null,
                  onSelected: (_) => _selectDateRange(),
                  avatar: Icon(
                    Icons.date_range,
                    size: 18,
                    color: _selectedDateRange != null ? Colors.blue : null,
                  ),
                ),
                const SizedBox(width: 8),

                // Account filter
                PopupMenuButton<String>(
                  child: Chip(
                    label: Text(_selectedAccount ?? 'Account'),
                    avatar: Icon(
                      Icons.account_balance_wallet,
                      size: 18,
                      color: _selectedAccount != null ? Colors.blue : null,
                    ),
                    backgroundColor: _selectedAccount != null
                        ? Colors.blue[100]
                        : Colors.grey[200],
                  ),
                  onSelected: (value) {
                    setState(() {
                      _selectedAccount = value;
                    });
                    _applyFilters();
                  },
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Accounts'),
                      ),
                      ...provider.accounts.map((account) {
                        return PopupMenuItem(
                          value: account.name,
                          child: Text(account.name),
                        );
                      }).toList(),
                    ];
                  },
                ),
                const SizedBox(width: 8),

                // Tag filter
                FutureBuilder<List<String>>(
                  future: provider.getAllTags(),
                  builder: (context, snapshot) {
                    final tags = snapshot.data ?? [];
                    if (tags.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return PopupMenuButton<String>(
                      child: Chip(
                        label: Text(_selectedTag ?? 'Tag'),
                        avatar: Icon(
                          Icons.label,
                          size: 18,
                          color: _selectedTag != null ? Colors.blue : null,
                        ),
                        backgroundColor: _selectedTag != null
                            ? Colors.blue[100]
                            : Colors.grey[200],
                      ),
                      onSelected: (value) {
                        setState(() {
                          _selectedTag = value;
                        });
                        _applyFilters();
                      },
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem(
                            value: null,
                            child: Text('All Tags'),
                          ),
                          ...tags.map((tag) {
                            return PopupMenuItem(
                              value: tag,
                              child: Text(tag),
                            );
                          }).toList(),
                        ];
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isDebit = transaction.type == TransactionType.debit;
    final color = isDebit ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(transaction: transaction),
            ),
          );

          // Refresh after edit
          await context.read<AppProvider>().initialize();
          _applyFilters();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tag and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.tag,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(transaction.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isDebit ? '-' : '+'}${NumberFormat.currency(symbol: '₹').format(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Net: ${NumberFormat.currency(symbol: '₹').format(transaction.net)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Account and delta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getAccountIcon(transaction.account),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        transaction.account,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Δ ${NumberFormat.currency(symbol: '₹').format(transaction.delta)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // Moneyback indicator
              if (transaction.moneyback > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payments,
                        size: 14,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Moneyback: ${NumberFormat.currency(symbol: '₹').format(transaction.moneyback)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: 22,
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
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildDetailRow(
                            'Date',
                            DateFormat('MMM dd, yyyy')
                                .format(transaction.date)),
                        _buildDetailRow('Type', transaction.type.displayName),
                        _buildDetailRow(
                          'Amount',
                          NumberFormat.currency(symbol: '₹')
                              .format(transaction.amount),
                        ),
                        _buildDetailRow('Account', transaction.account),
                        _buildDetailRow('Tag', transaction.tag),
                        _buildDetailRow(
                          'Delta',
                          NumberFormat.currency(symbol: '₹')
                              .format(transaction.delta),
                        ),
                        _buildDetailRow(
                          'Net at Transaction',
                          NumberFormat.currency(symbol: '₹')
                              .format(transaction.net),
                        ),
                        if (transaction.moneyback > 0)
                          _buildDetailRow(
                            'Moneyback',
                            NumberFormat.currency(symbol: '₹')
                                .format(transaction.moneyback),
                          ),
                        if (transaction.remarks.isNotEmpty)
                          _buildDetailRow('Remarks', transaction.remarks),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
}
