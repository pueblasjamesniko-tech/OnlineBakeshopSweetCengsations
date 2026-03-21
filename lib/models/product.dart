class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String emoji;
  final String category;
  final bool isBestSeller;
  final double rating;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    required this.category,
    this.isBestSeller = false,
    this.rating = 4.5,
    this.quantity = 0,
  });
}

class ProductData {
  static List<Product> getAllProducts() {
    return [
      // Cakes
      Product(
        id: '1',
        name: 'Velvet Dream Cake',
        description: 'Lush red velvet with cream cheese frosting & rose petals',
        price: 850,
        emoji: '🎂',
        category: 'Cakes',
        isBestSeller: true,
        rating: 4.9,
      ),
      Product(
        id: '2',
        name: 'Salted Caramel Tower',
        description: 'Six-layer caramel sponge with salted butterscotch drizzle',
        price: 1200,
        emoji: '🍰',
        category: 'Cakes',
        rating: 4.8,
      ),
      Product(
        id: '3',
        name: 'Dark Choco Truffle',
        description: 'Belgian chocolate ganache with 72% dark cacao center',
        price: 950,
        emoji: '🍫',
        category: 'Cakes',
        isBestSeller: true,
        rating: 4.7,
      ),
      // Pastries
      Product(
        id: '4',
        name: 'Honey Butter Croissant',
        description: 'Flaky laminated dough with pure wildflower honey glaze',
        price: 85,
        emoji: '🥐',
        category: 'Pastries',
        isBestSeller: true,
        rating: 4.9,
      ),
      Product(
        id: '5',
        name: 'Cinnamon Cloud Bun',
        description: 'Pillowy soft bun swirled with cinnamon brown sugar',
        price: 75,
        emoji: '🌀',
        category: 'Pastries',
        rating: 4.6,
      ),
      Product(
        id: '6',
        name: 'Almond Pear Tart',
        description: 'Buttery shell with frangipane & caramelized pears',
        price: 165,
        emoji: '🥧',
        category: 'Pastries',
        rating: 4.7,
      ),
      // Cookies
      Product(
        id: '7',
        name: 'Sea Salt Brownie',
        description: 'Fudgy thick brownie with Himalayan pink salt flakes',
        price: 60,
        emoji: '🍫',
        category: 'Cookies',
        isBestSeller: true,
        rating: 5.0,
      ),
      Product(
        id: '8',
        name: 'Matcha Crinkle',
        description: 'Soft Japanese matcha cookies dusted in powdered sugar',
        price: 55,
        emoji: '🍪',
        category: 'Cookies',
        rating: 4.5,
      ),
      // Drinks
      Product(
        id: '9',
        name: 'Café Mocha Latte',
        description: 'House espresso with velvety steamed milk & cacao drizzle',
        price: 150,
        emoji: '☕',
        category: 'Drinks',
        rating: 4.8,
      ),
      Product(
        id: '10',
        name: 'Rose Milk Tea',
        description: 'Fragrant rose-infused milk tea with honey boba pearls',
        price: 130,
        emoji: '🧋',
        category: 'Drinks',
        isBestSeller: true,
        rating: 4.9,
      ),
    ];
  }

  static List<String> getCategories() {
    return ['All', 'Cakes', 'Pastries', 'Cookies', 'Drinks'];
  }
}
