class WithdrawalModel {
  final int id;
  // Not always present in API resources (e.g. user routes)
  final int? userId;
  final double amount;
  final double fee;
  final double netAmount;
  final String phoneNumber;
  final String provider;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;
  final String? notes;
  final String? rejectionReason;
  final String? transactionReference;

  WithdrawalModel({
    required this.id,
    this.userId,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.phoneNumber,
    required this.provider,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
    this.notes,
    this.rejectionReason,
    this.transactionReference,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'].toString());
    final updatedAtStr = json['updated_at'] ?? json['created_at'];

    return WithdrawalModel(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']),
      amount: (json['amount'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      netAmount: (json['net_amount'] ?? 0).toDouble(),
      phoneNumber: json['phone_number'] ?? '',
      provider: json['provider'] ?? '',
      status: json['status'] ?? '',
      createdAt: createdAt,
      // Some endpoints/resources don't include updated_at; fallback to created_at.
      updatedAt: DateTime.parse(updatedAtStr.toString()),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'].toString())
          : null,
      notes: json['notes'],
      rejectionReason: json['rejection_reason'],
      transactionReference: json['transaction_reference'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'amount': amount,
      'fee': fee,
      'net_amount': netAmount,
      'phone_number': phoneNumber,
      'provider': provider,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'notes': notes,
      'rejection_reason': rejectionReason,
      'transaction_reference': transactionReference,
    };
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRejected => status == 'rejected';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En cours de traitement';
      case 'completed':
        return 'Complété';
      case 'failed':
        return 'Échoué';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }

  String get providerName {
    switch (provider) {
      case 'mtn_momo':
        return 'MTN Mobile Money';
      case 'orange_money':
        return 'Orange Money';
      default:
        return provider;
    }
  }

  String get providerIcon {
    switch (provider) {
      case 'mtn_momo':
        return '📱'; // MTN logo
      case 'orange_money':
        return '🍊'; // Orange logo
      default:
        return '💳';
    }
  }

  String get formattedAmount {
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  String get formattedNetAmount {
    return '${netAmount.toStringAsFixed(0)} FCFA';
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class WithdrawalListResponse {
  final List<WithdrawalModel> withdrawals;
  final WithdrawalMeta meta;

  WithdrawalListResponse({
    required this.withdrawals,
    required this.meta,
  });

  factory WithdrawalListResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawalListResponse(
      withdrawals: (json['withdrawals'] as List)
          .map((e) => WithdrawalModel.fromJson(e))
          .toList(),
      meta: WithdrawalMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

class WithdrawalMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  WithdrawalMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory WithdrawalMeta.fromJson(Map<String, dynamic> json) {
    return WithdrawalMeta(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

class WithdrawalMethod {
  final String id;
  final String name;
  final String icon;
  final bool isAvailable;

  WithdrawalMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.isAvailable,
  });

  factory WithdrawalMethod.fromJson(Map<String, dynamic> json) {
    return WithdrawalMethod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      isAvailable: json['is_available'] ?? false,
    );
  }
}

class WithdrawalMethodsResponse {
  final List<WithdrawalMethod> methods;
  final double minimumAmount;
  final double fee;
  final String currency;

  WithdrawalMethodsResponse({
    required this.methods,
    required this.minimumAmount,
    required this.fee,
    required this.currency,
  });

  factory WithdrawalMethodsResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawalMethodsResponse(
      methods: (json['methods'] as List)
          .map((e) => WithdrawalMethod.fromJson(e))
          .toList(),
      minimumAmount: (json['minimum_amount'] ?? 1000).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'XAF',
    );
  }
}
