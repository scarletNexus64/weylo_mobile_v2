class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'read_at': readAt,
      'created_at': createdAt,
    };
  }

  /// Returns the notification icon based on type
  String getIcon() {
    switch (type) {
      case 'message':
      case 'new_chat_message':
      case 'new_message':
        return '💬';
      case 'confession':
      case 'anonymous_message':
        return '💭';
      case 'gift':
      case 'gift_received':
      case 'gift_sent':
        return '🎁';
      case 'like':
        return '❤️';
      case 'comment':
        return '💬';
      case 'follow':
      case 'new_follower':
        return '👤';
      case 'premium':
      case 'premium_upgrade':
        return '⭐';
      case 'wallet':
      case 'wallet_credit':
      case 'wallet_debit':
        return '💰';
      default:
        return '🔔';
    }
  }
}

class NotificationListResponse {
  final List<NotificationModel> notifications;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  NotificationListResponse({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      notifications: (json['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList(),
      currentPage: json['meta']['current_page'] as int,
      lastPage: json['meta']['last_page'] as int,
      perPage: json['meta']['per_page'] as int,
      total: json['meta']['total'] as int,
    );
  }
}
