/// Represents an account (Bank, Cash, or Wallet)
class Account {
  final String name;
  final double balance;

  Account({
    required this.name,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'balance': balance,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      name: map['name'] as String,
      balance: map['balance'] as double,
    );
  }

  Account copyWith({
    String? name,
    double? balance,
  }) {
    return Account(
      name: name ?? this.name,
      balance: balance ?? this.balance,
    );
  }
}
