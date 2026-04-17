class ProductModel {
  final int productId;
  final String productName;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  const ProductModel({
    required this.productId,
    required this.productName,
    required this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}
