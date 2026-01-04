/// Transaction type enum
enum TransactionType {
  debit,
  credit;

  String get displayName {
    switch (this) {
      case TransactionType.debit:
        return 'Debit';
      case TransactionType.credit:
        return 'Credit';
    }
  }
}

/// Represents a single transaction
class Transaction {
  final int? id;
  final DateTime date;
  final TransactionType type;
  final double amount;
  final String account; // Bank, Cash, or Wallet
  final String tag;
  final double moneyback; // Amount expected to get back
  final String remarks;
  final double delta; // Calculated: +amount for credit, -amount for debit
  final double net; // Calculated: sum of all account balances at this point

  Transaction({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.account,
    required this.tag,
    this.moneyback = 0.0,
    this.remarks = '',
    required this.delta,
    required this.net,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type == TransactionType.debit ? 'debit' : 'credit',
      'amount': amount,
      'account': account,
      'tag': tag,
      'moneyback': moneyback,
      'remarks': remarks,
      'delta': delta,
      'net': net,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] == 'debit' ? TransactionType.debit : TransactionType.credit,
      amount: map['amount'] as double,
      account: map['account'] as String,
      tag: map['tag'] as String,
      moneyback: map['moneyback'] as double,
      remarks: map['remarks'] as String,
      delta: map['delta'] as double,
      net: map['net'] as double,
    );
  }

  Transaction copyWith({
    int? id,
    DateTime? date,
    TransactionType? type,
    double? amount,
    String? account,
    String? tag,
    double? moneyback,
    String? remarks,
    double? delta,
    double? net,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      account: account ?? this.account,
      tag: tag ?? this.tag,
      moneyback: moneyback ?? this.moneyback,
      remarks: remarks ?? this.remarks,
      delta: delta ?? this.delta,
      net: net ?? this.net,
    );
  }
}
