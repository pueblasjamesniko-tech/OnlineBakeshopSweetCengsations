class ProductModel {
  final int productId;
  final String productName;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  ProductModel({
    required this.productId,
    required this.productName,
    required this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] as int? ?? 0,
      productName: json['productName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['imageUrl']?.toString(),
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }
}
