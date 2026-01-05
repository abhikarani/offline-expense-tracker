import 'package:shared_preferences/shared_preferences.dart';

/// Model for storing notification transaction defaults
class NotificationPreferences {
  final String? defaultAccount;
  final String? defaultTag;
  final bool defaultIsEssential;
  final bool useAccountAutoDetection;
  final bool useTagAutoDetection;

  const NotificationPreferences({
    this.defaultAccount,
    this.defaultTag,
    this.defaultIsEssential = true,
    this.useAccountAutoDetection = true,
    this.useTagAutoDetection = true,
  });

  // SharedPreferences keys
  static const String _keyDefaultAccount = 'notif_default_account';
  static const String _keyDefaultTag = 'notif_default_tag';
  static const String _keyDefaultIsEssential = 'notif_default_is_essential';
  static const String _keyUseAccountAutoDetection = 'notif_use_account_auto';
  static const String _keyUseTagAutoDetection = 'notif_use_tag_auto';

  /// Load preferences from SharedPreferences
  static Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      defaultAccount: prefs.getString(_keyDefaultAccount),
      defaultTag: prefs.getString(_keyDefaultTag),
      defaultIsEssential: prefs.getBool(_keyDefaultIsEssential) ?? true,
      useAccountAutoDetection: prefs.getBool(_keyUseAccountAutoDetection) ?? true,
      useTagAutoDetection: prefs.getBool(_keyUseTagAutoDetection) ?? true,
    );
  }

  /// Save preferences to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    if (defaultAccount != null) {
      await prefs.setString(_keyDefaultAccount, defaultAccount!);
    } else {
      await prefs.remove(_keyDefaultAccount);
    }

    if (defaultTag != null) {
      await prefs.setString(_keyDefaultTag, defaultTag!);
    } else {
      await prefs.remove(_keyDefaultTag);
    }

    await prefs.setBool(_keyDefaultIsEssential, defaultIsEssential);
    await prefs.setBool(_keyUseAccountAutoDetection, useAccountAutoDetection);
    await prefs.setBool(_keyUseTagAutoDetection, useTagAutoDetection);
  }

  /// Create a copy with updated values
  NotificationPreferences copyWith({
    String? defaultAccount,
    String? defaultTag,
    bool? defaultIsEssential,
    bool? useAccountAutoDetection,
    bool? useTagAutoDetection,
    bool clearAccount = false,
    bool clearTag = false,
  }) {
    return NotificationPreferences(
      defaultAccount: clearAccount ? null : (defaultAccount ?? this.defaultAccount),
      defaultTag: clearTag ? null : (defaultTag ?? this.defaultTag),
      defaultIsEssential: defaultIsEssential ?? this.defaultIsEssential,
      useAccountAutoDetection: useAccountAutoDetection ?? this.useAccountAutoDetection,
      useTagAutoDetection: useTagAutoDetection ?? this.useTagAutoDetection,
    );
  }
}
