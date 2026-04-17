import 'product_model.dart';

class CartItem {
  final bool isCustom;

  // ── Regular order fields ──────────────────────────────────
  ProductModel? product;
  int quantity;
  String? deliveryDate;
  String? deliveryTime;
  String? deliveryAddress;
  String? specialNotes;

  // ── Custom order fields ───────────────────────────────────
  final String? customLabel;
  final String? customEmoji;
  final Map<String, dynamic>? customData;

  CartItem._({
    required this.isCustom,
    this.product,
    this.quantity = 1,
    this.deliveryDate,
    this.deliveryTime,
    this.deliveryAddress,
    this.specialNotes,
    this.customLabel,
    this.customEmoji,
    this.customData,
  });

  factory CartItem.regular({
    required ProductModel product,
    required int quantity,
    required String deliveryDate,
    required String deliveryTime,
    required String deliveryAddress,
    String? specialNotes,
  }) =>
      CartItem._(
        isCustom: false,
        product: product,
        quantity: quantity,
        deliveryDate: deliveryDate,
        deliveryTime: deliveryTime,
        deliveryAddress: deliveryAddress,
        specialNotes: specialNotes,
      );

  factory CartItem.custom({
    required String customLabel,
    required String customEmoji,
    required Map<String, dynamic> customData,
  }) =>
      CartItem._(
        isCustom: true,
        quantity: 1,
        customLabel: customLabel,
        customEmoji: customEmoji,
        customData: customData,
      );

  double get lineTotal => isCustom ? 0.0 : (product?.price ?? 0.0) * quantity;

  String get displayName =>
      isCustom ? (customLabel ?? 'Custom Order') : (product?.productName ?? '');

  String get displayEmoji => isCustom ? (customEmoji ?? '🎂') : '🎂';

  // ── Serialization (only for regular items) ────────────────
  Map<String, dynamic> toJson() {
    return {
      'isCustom': isCustom,
      'quantity': quantity,
      'deliveryDate': deliveryDate,
      'deliveryTime': deliveryTime,
      'deliveryAddress': deliveryAddress,
      'specialNotes': specialNotes,
      'product': product?.toJson(),
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem._(
      isCustom: json['isCustom'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
      deliveryDate: json['deliveryDate'] as String?,
      deliveryTime: json['deliveryTime'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      specialNotes: json['specialNotes'] as String?,
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
}
