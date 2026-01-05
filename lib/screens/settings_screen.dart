import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/notification_preferences.dart';

/// Screen for configuring notification transaction defaults
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  NotificationPreferences _preferences = const NotificationPreferences();
  List<String> _availableAccounts = [];
  List<String> _availableTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();

      // Load accounts and tags
      final accounts = provider.accounts.map((a) => a.name).toList();
      final tags = await provider.getActiveTags();

      // Load saved preferences
      final prefs = await NotificationPreferences.load();

      setState(() {
        _availableAccounts = accounts;
        _availableTags = tags;
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _preferences.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Configure default values for transactions auto-recorded from notifications.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Account Settings Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Auto-detect account'),
                          subtitle: const Text(
                            'Automatically detect account from notification keywords',
                          ),
                          value: _preferences.useAccountAutoDetection,
                          onChanged: (value) {
                            setState(() {
                              _preferences = _preferences.copyWith(
                                useAccountAutoDetection: value,
                              );
                            });
                          },
                          contentPadding: const EdgeInsets.all(0),
                        ),
                        if (!_preferences.useAccountAutoDetection) ...[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _preferences.defaultAccount != null &&
                                    _availableAccounts.contains(_preferences.defaultAccount)
                                ? _preferences.defaultAccount
                                : null,
                            items: _availableAccounts
                                .map((a) => DropdownMenuItem(
                                      value: a,
                                      child: Text(a),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _preferences = _preferences.copyWith(
                                  defaultAccount: v,
                                );
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Default Account *',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Select default account'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tag Settings Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.label, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Tag',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Auto-detect tag'),
                          subtitle: const Text(
                            'Automatically detect tag from merchant/service names',
                          ),
                          value: _preferences.useTagAutoDetection,
                          onChanged: (value) {
                            setState(() {
                              _preferences = _preferences.copyWith(
                                useTagAutoDetection: value,
                              );
                            });
                          },
                          contentPadding: const EdgeInsets.all(0),
                        ),
                        if (!_preferences.useTagAutoDetection) ...[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _preferences.defaultTag != null &&
                                    _availableTags.contains(_preferences.defaultTag)
                                ? _preferences.defaultTag
                                : null,
                            items: _availableTags
                                .map((tag) => DropdownMenuItem(
                                      value: tag,
                                      child: Text(tag),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _preferences = _preferences.copyWith(
                                  defaultTag: v,
                                );
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Default Tag *',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Select default tag'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Essential/Non-Essential Settings Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Expense Type',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Default to Essential'),
                          subtitle: Text(
                            _preferences.defaultIsEssential
                                ? 'Notifications will be marked as essential expenses'
                                : 'Notifications will be marked as non-essential expenses',
                          ),
                          value: _preferences.defaultIsEssential,
                          onChanged: (value) {
                            setState(() {
                              _preferences = _preferences.copyWith(
                                defaultIsEssential: value,
                              );
                            });
                          },
                          activeThumbColor: Colors.green,
                          inactiveThumbColor: Colors.orange,
                          contentPadding: const EdgeInsets.all(0),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info section
                Card(
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How it works:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '• When auto-detection is ON, the app will try to identify account and tag from notification text\n'
                                '• When auto-detection is OFF, all notifications will use your selected default values\n'
                                '• You can always edit transactions manually after they are recorded',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
