import 'dart:typed_data';
import 'product_model.dart';

/// Represents a single item in the shopping cart.
/// Supports both regular (catalog) items and custom (cake/cupcake) orders.
class CartItem {
  // Server-side ID (set after UpsertCartItem succeeds)
  int? cartId;

  // Regular order fields
  final ProductModel? product;
  int quantity;
  final String? deliveryDate;
  final String? deliveryTime;
  final String? deliveryAddress;
  final String? specialNotes;
  final String? paymentMethod;
  final String? fulfillmentType;
  final String? meetupPlace;

  // GCash receipt (in-memory only, uploaded separately)
  Uint8List? receiptBytes;
  String? receiptFileName;

  // Custom order fields
  final bool isCustom;
  final String? customLabel; // e.g. "Custom Cake"
  final String? customEmoji; // e.g. "🎂"
  final Map<String, dynamic>? customData;

  // Private constructor
  CartItem._({
    this.cartId,
    this.product,
    this.quantity = 1,
    this.deliveryDate,
    this.deliveryTime,
    this.deliveryAddress,
    this.specialNotes,
    this.paymentMethod,
    this.fulfillmentType,
    this.meetupPlace,
    this.receiptBytes,
    this.receiptFileName,
    required this.isCustom,
    this.customLabel,
    this.customEmoji,
    this.customData,
  });

  // Factory: regular catalog item
  factory CartItem.regular({
    required ProductModel product,
    required int quantity,
    required String deliveryDate,
    required String deliveryTime,
    required String deliveryAddress,
    String? specialNotes,
    required String paymentMethod,
    required String fulfillmentType,
    String? meetupPlace,
  }) {
    return CartItem._(
      product: product,
      quantity: quantity,
      deliveryDate: deliveryDate,
      deliveryTime: deliveryTime,
      deliveryAddress: deliveryAddress,
      specialNotes: specialNotes,
      paymentMethod: paymentMethod,
      fulfillmentType: fulfillmentType,
      meetupPlace: meetupPlace,
      isCustom: false,
    );
  }

  // Factory: custom cake / cupcake order

  factory CartItem.custom({
    required String customLabel,
    required String customEmoji,
    required Map<String, dynamic> customData,
  }) {
    return CartItem._(
      isCustom: true,
      customLabel: customLabel,
      customEmoji: customEmoji,
      customData: customData,
      quantity: 1,
    );
  }

  // Computed helpers

  /// Display name shown in cart UI.
  String get displayName =>
      isCustom ? (customLabel ?? 'Custom Order') : (product?.productName ?? '');

  /// Display emoji shown in cart UI.
  String get displayEmoji => isCustom ? (customEmoji ?? '🎂') : '🎂';

  /// Total price for this line (0 for custom orders until quoted).
  double get lineTotal => isCustom ? 0.0 : (product?.price ?? 0.0) * quantity;

  // JSON helpers (for local persistence fallback)

  Map<String, dynamic> toJson() => {
        'cartId': cartId,
        'isCustom': isCustom,
        'quantity': quantity,
        'deliveryDate': deliveryDate,
        'deliveryTime': deliveryTime,
        'deliveryAddress': deliveryAddress,
        'specialNotes': specialNotes,
        'paymentMethod': paymentMethod,
        'fulfillmentType': fulfillmentType,
        'meetupPlace': meetupPlace,
        'customLabel': customLabel,
        'customEmoji': customEmoji,
        'customData': customData,
        if (product != null) 'product': product!.toJson(),
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final isCustom = json['isCustom'] as bool? ?? false;
    if (isCustom) {
      return CartItem.custom(
        customLabel: json['customLabel'] as String? ?? 'Custom Order',
        customEmoji: json['customEmoji'] as String? ?? '🎂',
        customData: (json['customData'] as Map<String, dynamic>?) ?? {},
      )..cartId = json['cartId'] as int?;
    }

    final productJson = json['product'] as Map<String, dynamic>?;
    return CartItem.regular(
      product: productJson != null
          ? ProductModel.fromJson(productJson)
          : ProductModel(
              productId: 0,
              productName: '',
              description: '',
              price: 0,
              isAvailable: false,
            ),
      quantity: json['quantity'] as int? ?? 1,
      deliveryDate: json['deliveryDate'] as String? ?? '',
      deliveryTime: json['deliveryTime'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      specialNotes: json['specialNotes'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'COD',
      fulfillmentType: json['fulfillmentType'] as String? ?? 'Delivery',
      meetupPlace: json['meetupPlace'] as String?,
    )..cartId = json['cartId'] as int?;
  }
}
