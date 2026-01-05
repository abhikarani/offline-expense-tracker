import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// Screen for managing accounts (add, rename, delete)
class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _addAccountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _addAccountController.dispose();
    super.dispose();
  }

  Future<void> _addAccount() async {
    final accountName = _addAccountController.text.trim();
    if (accountName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an account name')),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final existingAccounts = provider.accounts.map((a) => a.name.toLowerCase()).toList();

    if (existingAccounts.contains(accountName.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account already exists')),
        );
      }
      return;
    }

    try {
      await provider.addAccount(accountName, 0.0);
      _addAccountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account "$accountName" added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding account: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount(String accountName) async {
    final provider = context.read<AppProvider>();

    // Check if account has transactions
    final hasTransactions = await provider.accountHasTransactions(accountName);

    if (hasTransactions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot delete "$accountName" - it has transactions'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "$accountName"?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await provider.deleteAccount(accountName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account "$accountName" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  Future<void> _renameAccount(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Account'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New account name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == oldName) return;

    final provider = context.read<AppProvider>();
    final existingAccounts = provider.accounts.map((a) => a.name.toLowerCase()).toList();

    if (existingAccounts.contains(newName.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account with this name already exists')),
        );
      }
      return;
    }

    try {
      await provider.renameAccount(oldName, newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account renamed to "$newName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error renaming account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = provider.accounts;

          return Column(
            children: [
              // Add account section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addAccountController,
                        decoration: const InputDecoration(
                          labelText: 'Add new account',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        onSubmitted: (_) => _addAccount(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addAccount,
                      icon: const Icon(Icons.add_circle),
                      iconSize: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Accounts list
              Expanded(
                child: accounts.isEmpty
                    ? const Center(
                        child: Text(
                          'No accounts yet.\nAdd one above!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  account.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                account.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Balance: ₹${account.balance.toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _renameAccount(account.name),
                                    tooltip: 'Rename',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteAccount(account.name),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
