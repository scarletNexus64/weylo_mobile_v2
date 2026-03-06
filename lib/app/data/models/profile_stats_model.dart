class ProfileStatsModel {
  final MessageStats messages;
  final ConfessionStats confessions;
  final ConversationStats conversations;
  final GiftStats gifts;
  final WalletStats wallet;
  final int streakDays;

  ProfileStatsModel({
    required this.messages,
    required this.confessions,
    required this.conversations,
    required this.gifts,
    required this.wallet,
    this.streakDays = 0,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return ProfileStatsModel(
      messages: MessageStats.fromJson(json['messages'] ?? {}),
      confessions: ConfessionStats.fromJson(json['confessions'] ?? {}),
      conversations: ConversationStats.fromJson(json['conversations'] ?? {}),
      gifts: GiftStats.fromJson(json['gifts'] ?? {}),
      wallet: WalletStats.fromJson(json['wallet'] ?? {}),
      streakDays: json['streak_days'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages.toJson(),
      'confessions': confessions.toJson(),
      'conversations': conversations.toJson(),
      'gifts': gifts.toJson(),
      'wallet': wallet.toJson(),
      'streak_days': streakDays,
    };
  }
}

class MessageStats {
  final int received;
  final int sent;
  final int unread;

  MessageStats({
    this.received = 0,
    this.sent = 0,
    this.unread = 0,
  });

  factory MessageStats.fromJson(Map<String, dynamic> json) {
    return MessageStats(
      received: json['received'] ?? 0,
      sent: json['sent'] ?? 0,
      unread: json['unread'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'received': received,
      'sent': sent,
      'unread': unread,
    };
  }

  int get total => received + sent;
}

class ConfessionStats {
  final int received;
  final int sent;

  ConfessionStats({
    this.received = 0,
    this.sent = 0,
  });

  factory ConfessionStats.fromJson(Map<String, dynamic> json) {
    return ConfessionStats(
      received: json['received'] ?? 0,
      sent: json['sent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'received': received,
      'sent': sent,
    };
  }

  int get total => received + sent;
}

class ConversationStats {
  final int total;
  final int active;

  ConversationStats({
    this.total = 0,
    this.active = 0,
  });

  factory ConversationStats.fromJson(Map<String, dynamic> json) {
    return ConversationStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active': active,
    };
  }
}

class GiftStats {
  final int received;
  final int sent;

  GiftStats({
    this.received = 0,
    this.sent = 0,
  });

  factory GiftStats.fromJson(Map<String, dynamic> json) {
    return GiftStats(
      received: json['received'] ?? 0,
      sent: json['sent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'received': received,
      'sent': sent,
    };
  }

  int get total => received + sent;
}

class WalletStats {
  final double balance;
  final String formatted;

  WalletStats({
    this.balance = 0.0,
    this.formatted = '0 FCFA',
  });

  factory WalletStats.fromJson(Map<String, dynamic> json) {
    return WalletStats(
      balance: (json['balance'] ?? 0).toDouble(),
      formatted: json['formatted'] ?? '0 FCFA',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'formatted': formatted,
    };
  }
}
