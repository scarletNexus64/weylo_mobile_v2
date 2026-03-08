class GiftModel {
  final int id;
  final String name;
  final String description;
  final int price;
  final String tier; // 'bronze', 'silver', 'gold', 'diamond'
  final String? iconUrl;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  GiftModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.tier,
    this.iconUrl,
    this.imageUrl,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      tier: json['tier'] as String? ?? 'bronze',
      iconUrl: json['icon_url'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'tier': tier,
      'icon_url': iconUrl,
      'image_url': imageUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedPrice => '$price FCFA';
}

class GiftTransactionModel {
  final int id;
  final int senderId;
  final int recipientId;
  final int giftId;
  final String status; // 'pending', 'completed', 'failed'
  final GiftModel gift;
  final GiftUser? sender;
  final GiftUser? recipient;
  final DateTime createdAt;

  GiftTransactionModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.giftId,
    required this.status,
    required this.gift,
    this.sender,
    this.recipient,
    required this.createdAt,
  });

  factory GiftTransactionModel.fromJson(Map<String, dynamic> json) {
    return GiftTransactionModel(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      recipientId: json['recipient_id'] as int,
      giftId: json['gift_id'] as int,
      status: json['status'] as String? ?? 'pending',
      gift: GiftModel.fromJson(json['gift'] as Map<String, dynamic>),
      sender: json['sender'] != null
          ? GiftUser.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      recipient: json['recipient'] != null
          ? GiftUser.fromJson(json['recipient'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'gift_id': giftId,
      'status': status,
      'gift': gift.toJson(),
      'sender': sender?.toJson(),
      'recipient': recipient?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class GiftUser {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String? avatarUrl;

  GiftUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.avatarUrl,
  });

  factory GiftUser.fromJson(Map<String, dynamic> json) {
    return GiftUser(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'avatar_url': avatarUrl,
    };
  }

  String get fullName => '$firstName $lastName'.trim();
}

class GiftListResponse {
  final List<GiftTransactionModel> gifts;
  final GiftMeta meta;

  GiftListResponse({
    required this.gifts,
    required this.meta,
  });

  factory GiftListResponse.fromJson(Map<String, dynamic> json) {
    // L'API renvoie 'transactions' au lieu de 'gifts'
    final transactionsList = json['transactions'] as List? ?? [];

    return GiftListResponse(
      gifts: transactionsList
          .map((item) => GiftTransactionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: GiftMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class GiftMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  GiftMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory GiftMeta.fromJson(Map<String, dynamic> json) {
    return GiftMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
