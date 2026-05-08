// A product with its details like name, price, and availability
class ProductModel {
  final int productId;
  final String productName;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  // Creates a product — all fields are required except imageUrl and isAvailable
  ProductModel({
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
      productId: json['productId'] as int? ?? 0,
      productName: json['productName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['imageUrl']?.toString(),
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  // Turns the product back into a JSON map (e.g. to send to an API)
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

  // Shows all product info as a single readable text
  @override
  String toString() {
    return 'productId: $productId, productName: $productName, description: $description, price: $price, imageUrl: $imageUrl, isAvailable: $isAvailable';
  }
}
