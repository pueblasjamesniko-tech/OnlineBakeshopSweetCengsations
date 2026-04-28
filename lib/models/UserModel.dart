class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarEmoji;
  final String? profilePicture;
  final int orderCount;
  final int favouriteCount;
  final int points;
  final List<OrderModel> recentOrders;
  final List<String> savedAddresses;
  final String? phone;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarEmoji,
    this.profilePicture,
    this.orderCount = 0,
    this.favouriteCount = 0,
    this.points = 0,
    this.recentOrders = const [],
    this.savedAddresses = const [],
    this.phone,
    this.token,
  });

  /// Creates a UserModel from a JSON map (e.g. from your backend response).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['full_name'] ?? 'User',
      email: json['email'] ?? '',
      avatarEmoji: json['avatar_emoji'],
      orderCount: json['order_count'] ?? json['orders_count'] ?? 0,
      favouriteCount: json['favourite_count'] ?? json['favorites_count'] ?? 0,
      points: json['points'] ?? json['loyalty_points'] ?? 0,
      phone: json['phone'] ?? json['phone_number'],
      recentOrders: (json['recent_orders'] as List<dynamic>? ?? [])
          .map((o) => OrderModel.fromJson(o as Map<String, dynamic>))
          .toList(),
      savedAddresses: (json['saved_addresses'] as List<dynamic>? ?? [])
          .map((a) => a.toString())
          .toList(),
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_emoji': avatarEmoji,
        'order_count': orderCount,
        'favourite_count': favouriteCount,
        'points': points,
        'phone': phone,
        'token': token,
      };

  /// Returns just the first name for greetings.
  String get firstName => name.split(' ').first;
}

// ── OrderModel ────────────────────────────────────────────────────────────────
class OrderModel {
  final String id;
  final String status; // e.g. 'Delivered', 'Pending', 'Processing'
  final double totalAmount;
  final DateTime orderedAt;
  final List<String> itemNames;

  const OrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.orderedAt,
    this.itemNames = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? 'Pending',
      totalAmount: (json['total_amount'] ?? json['total'] ?? 0).toDouble(),
      orderedAt: json['ordered_at'] != null
          ? DateTime.tryParse(json['ordered_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      itemNames: (json['item_names'] as List<dynamic>? ?? [])
          .map((n) => n.toString())
          .toList(),
    );
  }

  String get statusEmoji {
    switch (status.toLowerCase()) {
      case 'delivered':
        return '✅';
      case 'processing':
        return '🔄';
      case 'pending':
        return '⏳';
      case 'cancelled':
        return '❌';
      default:
        return '📦';
    }
  }
}
