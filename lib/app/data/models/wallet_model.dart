class WalletModel {
  final double balance;
  final String formattedBalance;
  final String currency;
  final WalletStats stats;

  WalletModel({
    required this.balance,
    required this.formattedBalance,
    required this.currency,
    required this.stats,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['balance'] ?? 0).toDouble(),
      formattedBalance: json['formatted_balance'] ?? '0 FCFA',
      currency: json['currency'] ?? 'XAF',
      stats: WalletStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'formatted_balance': formattedBalance,
      'currency': currency,
      'stats': stats.toJson(),
    };
  }

  WalletModel copyWith({
    double? balance,
    String? formattedBalance,
    String? currency,
    WalletStats? stats,
  }) {
    return WalletModel(
      balance: balance ?? this.balance,
      formattedBalance: formattedBalance ?? this.formattedBalance,
      currency: currency ?? this.currency,
      stats: stats ?? this.stats,
    );
  }
}

class WalletStats {
  final double totalEarnings;
  final double totalWithdrawals;
  final double pendingWithdrawals;

  WalletStats({
    required this.totalEarnings,
    required this.totalWithdrawals,
    required this.pendingWithdrawals,
  });

  factory WalletStats.fromJson(Map<String, dynamic> json) {
    return WalletStats(
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      totalWithdrawals: (json['total_withdrawals'] ?? 0).toDouble(),
      pendingWithdrawals: (json['pending_withdrawals'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'total_withdrawals': totalWithdrawals,
      'pending_withdrawals': pendingWithdrawals,
    };
  }
}

class WalletDetailedStats {
  final double balance;
  final EarningsStats earnings;
  final WithdrawalsStats withdrawals;
  final int transactionsCount;

  WalletDetailedStats({
    required this.balance,
    required this.earnings,
    required this.withdrawals,
    required this.transactionsCount,
  });

  factory WalletDetailedStats.fromJson(Map<String, dynamic> json) {
    return WalletDetailedStats(
      balance: (json['balance'] ?? 0).toDouble(),
      earnings: EarningsStats.fromJson(json['earnings'] ?? {}),
      withdrawals: WithdrawalsStats.fromJson(json['withdrawals'] ?? {}),
      transactionsCount: json['transactions_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'earnings': earnings.toJson(),
      'withdrawals': withdrawals.toJson(),
      'transactions_count': transactionsCount,
    };
  }
}

class EarningsStats {
  final double total;
  final double last30Days;
  final double last7Days;
  final double today;

  EarningsStats({
    required this.total,
    required this.last30Days,
    required this.last7Days,
    required this.today,
  });

  factory EarningsStats.fromJson(Map<String, dynamic> json) {
    return EarningsStats(
      total: (json['total'] ?? 0).toDouble(),
      last30Days: (json['last_30_days'] ?? 0).toDouble(),
      last7Days: (json['last_7_days'] ?? 0).toDouble(),
      today: (json['today'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'last_30_days': last30Days,
      'last_7_days': last7Days,
      'today': today,
    };
  }
}

class WithdrawalsStats {
  final double total;
  final double pending;
  final int count;

  WithdrawalsStats({
    required this.total,
    required this.pending,
    required this.count,
  });

  factory WithdrawalsStats.fromJson(Map<String, dynamic> json) {
    return WithdrawalsStats(
      total: (json['total'] ?? 0).toDouble(),
      pending: (json['pending'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'count': count,
    };
  }
}
