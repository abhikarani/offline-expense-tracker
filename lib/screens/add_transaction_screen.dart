import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../models/transaction.dart';
import 'tag_management_screen.dart';
import 'account_management_screen.dart';

/// Screen for adding OR editing a transaction
class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction; // null = add, non-null = edit

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  late DateTime _selectedDate;
  late TransactionType _type;
  final _amountController = TextEditingController();
  late String _selectedAccount;
  String? _selectedTag;
  late bool _isEssential;
  final _moneybackController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isLoading = false;
  List<String> _availableTags = [];
  List<String> _availableAccounts = [];

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _loadRecentTags();
    _loadAccounts();
    _initForm();
  }

  void _initForm() {
    if (_isEdit) {
      final tx = widget.transaction!;
      _selectedDate = tx.date;
      _type = tx.type;
      _selectedAccount = tx.account;
      _amountController.text = tx.amount.toString();
      _selectedTag = tx.tag;
      _isEssential = tx.isEssential;
      _moneybackController.text = tx.moneyback.toString();
      _remarksController.text = tx.remarks;
    } else {
      _selectedDate = DateTime.now();
      _type = TransactionType.debit;
      // Will be set when accounts load
      _isEssential = true;
      _moneybackController.text = '0';
    }
  }

  Future<void> _loadAccounts() async {
    final provider = context.read<AppProvider>();
    final accounts = provider.accounts.map((a) => a.name).toList();
    setState(() {
      _availableAccounts = accounts;
      // Set first account as default if adding new transaction
      if (!_isEdit && accounts.isNotEmpty) {
        _selectedAccount = accounts.first;
      }
      // Fix for editing transactions with deleted accounts
      if (_isEdit && !accounts.contains(_selectedAccount)) {
        _selectedAccount = accounts.isNotEmpty ? accounts.first : '';
      }
    });
  }

  Future<void> _loadRecentTags() async {
    final provider = context.read<AppProvider>();
    final tags = await provider.getActiveTags();
    setState(() {
      _availableTags = tags;
      // Set first tag as default if adding new transaction
      if (!_isEdit && _selectedTag == null && tags.isNotEmpty) {
        _selectedTag = tags.first;
      }
      // Fix for editing transactions with old tags (like "NA")
      // that don't exist in the new tag system
      if (_isEdit && _selectedTag != null && !tags.contains(_selectedTag)) {
        _selectedTag = tags.isNotEmpty ? tags.first : null;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _moneybackController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTag == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tag')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();

      if (_isEdit) {
        await provider.updateTransaction(
          oldTransaction: widget.transaction!,
          date: _selectedDate,
          type: _type,
          amount: double.parse(_amountController.text),
          account: _selectedAccount,
          tag: _selectedTag!,
          isEssential: _isEssential,
          moneyback: double.parse(_moneybackController.text),
          remarks: _remarksController.text.trim(),
        );
      } else {
        await provider.addTransaction(
          date: _selectedDate,
          type: _type,
          amount: double.parse(_amountController.text),
          account: _selectedAccount,
          tag: _selectedTag!,
          isEssential: _isEssential,
          moneyback: double.parse(_moneybackController.text),
          remarks: _remarksController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Transaction updated successfully'
                : 'Transaction added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTransaction,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEdit ? 'Update' : 'Save',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle:
                    Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.edit),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.debit,
                  label: Text('Debit'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TransactionType.credit,
                  label: Text('Credit'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount *',
                prefixText: '₹ ',
              ),
              validator: (v) => v == null ||
                      double.tryParse(v) == null ||
                      double.parse(v) <= 0
                  ? 'Enter valid amount'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAccount,
                    items: _availableAccounts
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAccount = v!),
                    decoration: const InputDecoration(
                      labelText: 'Account *',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Manage Accounts',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountManagementScreen(),
                      ),
                    );
                    // Reload accounts after returning from account management
                    await _loadAccounts();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTag,
                    items: _availableTags
                        .map((tag) => DropdownMenuItem(
                              value: tag,
                              child: Text(tag),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTag = v),
                    decoration: const InputDecoration(
                      labelText: 'Tag *',
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Manage Tags',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TagManagementScreen(),
                      ),
                    );
                    // Reload tags after returning from tag management
                    await _loadRecentTags();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Essential/Non-Essential toggle
            SwitchListTile(
              title: const Text('Essential Expense'),
              subtitle: Text(
                _isEssential
                    ? 'This is an essential expense'
                    : 'This is a non-essential expense',
              ),
              value: _isEssential,
              onChanged: (value) => setState(() => _isEssential = value),
              activeThumbColor: Colors.green,
              inactiveThumbColor: Colors.orange,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _moneybackController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Moneyback (Optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Remarks (Optional)'),
            ),
          ],
        ),
      ),
    );
  }
}
