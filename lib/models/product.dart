// A product with its details like name, price, and availability
class ProductModel {
  final int productId;
  final String productName;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  // Creates a product — all fields are required except imageUrl and isAvailable
  const ProductModel({
    required this.productId,
    required this.productName,
    required this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
  });

  // Builds a product from a JSON map (e.g. from an API response)
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
