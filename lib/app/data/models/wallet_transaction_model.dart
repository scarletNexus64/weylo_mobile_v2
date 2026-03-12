class WalletTransactionModel {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? reference;
  final Map<String, dynamic>? meta;

  WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    this.reference,
    this.meta,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      status: json['status'] ?? 'completed',
      createdAt: DateTime.parse(json['created_at']),
      reference: json['reference'],
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'reference': reference,
      'meta': meta,
    };
  }

  // Helpers pour l'affichage
  bool get isCredit => type == 'credit' || type == 'deposit';
  bool get isDebit => type == 'debit' || type == 'withdrawal';

  String get typeLabel {
    switch (type) {
      case 'credit':
      case 'deposit':
        return 'Dépôt';
      case 'debit':
      case 'withdrawal':
        return 'Retrait';
      case 'purchase':
        return 'Achat';
      case 'bonus':
        return 'Bonus';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'credit':
      case 'deposit':
        return '💰';
      case 'debit':
      case 'withdrawal':
        return '💸';
      case 'purchase':
        return '🛒';
      case 'bonus':
        return '🎁';
      default:
        return '📝';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En cours';
      case 'completed':
        return 'Complété';
      case 'failed':
        return 'Échoué';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  String get formattedAmount {
    final sign = isCredit ? '+' : '-';
    return '$sign${amount.toStringAsFixed(0)} FCFA';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

class TransactionListResponse {
  final List<WalletTransactionModel> transactions;
  final TransactionMeta meta;

  TransactionListResponse({
    required this.transactions,
    required this.meta,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    return TransactionListResponse(
      transactions: (json['transactions'] as List)
          .map((e) => WalletTransactionModel.fromJson(e))
          .toList(),
      meta: TransactionMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

class TransactionMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  TransactionMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory TransactionMeta.fromJson(Map<String, dynamic> json) {
    return TransactionMeta(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }

  bool get hasMore => currentPage < lastPage;
}
