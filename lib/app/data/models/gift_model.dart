class GiftModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String icon; // Emoji icon (ex: 🌹)
  final String animation; // Animation type
  final int price;
  final String formattedPrice; // Prix formaté depuis l'API
  final String tier; // 'bronze', 'silver', 'gold', 'diamond'
  final String tierColor; // Couleur du tier
  final String backgroundColor; // Couleur de fond
  final bool isActive;
  final int sortOrder;
  final int? categoryId;
  final GiftCategory? category;
  final DateTime? createdAt;

  GiftModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.animation,
    required this.price,
    required this.formattedPrice,
    required this.tier,
    required this.tierColor,
    required this.backgroundColor,
    required this.isActive,
    required this.sortOrder,
    this.categoryId,
    this.category,
    this.createdAt,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🎁', // Emoji par défaut
      animation: json['animation'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      formattedPrice: json['formatted_price'] as String? ?? '0 FCFA',
      tier: json['tier'] as String? ?? 'bronze',
      tierColor: json['tier_color'] as String? ?? '#CD7F32',
      backgroundColor: json['background_color'] as String? ?? '#FF6B6B',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      categoryId: json['category_id'] as int?,
      category: json['category'] != null
          ? GiftCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'animation': animation,
      'price': price,
      'formatted_price': formattedPrice,
      'tier': tier,
      'tier_color': tierColor,
      'background_color': backgroundColor,
      'is_active': isActive,
      'sort_order': sortOrder,
      'category_id': categoryId,
      'category': category?.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class GiftCategory {
  final int id;
  final String name;
  final bool isActive;
  final int? giftsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GiftCategory({
    required this.id,
    required this.name,
    required this.isActive,
    this.giftsCount,
    this.createdAt,
    this.updatedAt,
  });

  factory GiftCategory.fromJson(Map<String, dynamic> json) {
    return GiftCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      giftsCount: json['gifts_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive,
      'gifts_count': giftsCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
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
