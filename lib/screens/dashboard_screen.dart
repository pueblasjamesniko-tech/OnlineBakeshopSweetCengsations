import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../models/product_model.dart';
import '../../../models/cart_item.dart';
import '../../../models/user_session.dart';
import '../../../models/UserModel.dart';
import '../../../services/api_service.dart';
import 'notifications_screen.dart';
import 'delivery_addresses_screen.dart';

import 'login_screen.dart';
import 'custom_order_screen.dart';
import 'my_orders_screen.dart';
import 'my_custom_orders_screen.dart';
import 'help_support_screen.dart';

// Main screen with 3 tabs: Home, Cart, and Profile
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;
  final List<CartItem> _cart = [];
  List<ProductModel> _products = [];
  bool _isLoadingProducts = true;
  bool _cartLoaded = false;

  final GlobalKey<_CartTabState> _cartTabKey = GlobalKey<_CartTabState>();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  UserModel? get _user => UserSession.instance.currentUser;
  String get _userId => _user?.id ?? '';

  // Sets up the fade animation and loads cart + products on startup
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    _initLoad();
  }

  // Loads the saved cart first, then fetches the product list
  Future<void> _initLoad() async {
    await _loadPersistedCart();
    _loadProducts();
  }

  // Restores the user's cart from the server
  Future<void> _loadPersistedCart() async {
    if (_userId.isEmpty) return;
    final saved = await ApiService.loadCart(_userId);
    if (saved.isNotEmpty) {
      setState(() {
        _cart.clear();
        _cart.addAll(saved);
      });
    }
    _cartLoaded = true;
  }

  // Saves the current cart to the server
  Future<void> _persistCart() async {
    if (_userId.isEmpty) return;
    for (final item in _cart) {
      if (!item.isCustom) {
        if (item.cartId != null) {
          await ApiService.updateCartItemQty(_userId, item);
        } else {
          await ApiService.saveCartItem(_userId, item);
        }
      }
    }
  }

  // Cleans up the animation controller when the screen is closed
  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Fetches all products from the API
  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    final products = await ApiService.getAllProducts();
    setState(() {
      _products = products;
      _isLoadingProducts = false;
    });
  }

  // Total number of items in the cart // Total price of all items in the cart
  int get _cartCount => _cart.fold(0, (s, i) => s + i.quantity);
  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.lineTotal);

  // Adds an item to the cart, or increases its quantity if it's already there
  void _addToCart(CartItem item) {
    setState(() {
      if (!item.isCustom) {
        final existing = _cart.where((c) =>
            !c.isCustom && c.product?.productId == item.product?.productId);
        if (existing.isNotEmpty) {
          existing.first.quantity += item.quantity;
        } else {
          _cart.add(item);
        }
      }
    });
    _persistCart();
  }

  // Logs the user out and goes back to the login screen
  void _handleLogout() {
    ApiService.logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(
          index: _navIndex,
          children: [
            _HomeTab(
              products: _products,
              isLoading: _isLoadingProducts,
              cartCount: _cartCount,
              userName: UserSession.instance.firstName,
              onAddToCart: _addToCart,
              onCartTap: () => setState(() => _navIndex = 1),
              onCustomOrder: (type) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomOrderScreen(
                    orderType: type,
                    onSubmitted: (item) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Text('✨', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Custom order submitted! Check My Custom Orders to track it.',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppTheme.chocolate,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  ),
                ),
              ),
              onRefresh: _loadProducts,
            ),
            _CartTab(
              key: _cartTabKey,
              cart: _cart,
              total: _cartTotal,
              userId: _userId,
              onUpdate: () {
                setState(() {});
                _persistCart();
              },
              onOrdersPlaced: () async {
                await ApiService.clearCart(_userId);
              },
            ),
            _ProfileTab(
              user: _user,
              onLogout: _handleLogout,
              onUserUpdated: () => setState(() {}),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        cartCount: _cartCount,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

//
// HOME TAB
//
// Shows the greeting header, custom order cards, and product grid
class _HomeTab extends StatelessWidget {
  final List<ProductModel> products;
  final bool isLoading;
  final int cartCount;
  final String userName;
  final ValueChanged<CartItem> onAddToCart;
  final VoidCallback onCartTap;
  final ValueChanged<String> onCustomOrder;
  final Future<void> Function() onRefresh;

  const _HomeTab({
    required this.products,
    required this.isLoading,
    required this.cartCount,
    required this.userName,
    required this.onAddToCart,
    required this.onCartTap,
    required this.onCustomOrder,
    required this.onRefresh,
  });

  // Returns a greeting based on the current time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.chocolate,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.chocolateGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 22,
                right: 22,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                  'assets/images/bakeshop_logo.jpg',
                                  fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sweet Cengsations',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                              Text('✦ Artisan Bakeshop ✦',
                                  style: TextStyle(
                                      color: AppTheme.gold.withOpacity(0.85),
                                      fontSize: 10,
                                      letterSpacing: 1.5)),
                            ],
                          ),
                        ],
                      ),
                      // Cart icon button with item count badge
                      GestureDetector(
                        onTap: onCartTap,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined,
                                  color: Colors.white, size: 22),
                            ),
                            if (cartCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                      color: AppTheme.gold,
                                      shape: BoxShape.circle),
                                  child: Center(
                                    child: Text('$cartCount',
                                        style: const TextStyle(
                                            color: AppTheme.darkChoco,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('${_getGreeting()}, $userName! 🌅',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('What sweet treat\nare you craving?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2)),
                ],
              ),
            ),
          ),
          // Custom order section with cake and cupcake cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎨 Customize Your Order',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkChoco)),
                  const SizedBox(height: 4),
                  Text('Design your dream cake or cupcake!',
                      style: TextStyle(
                          color: AppTheme.chocolate.withOpacity(0.55),
                          fontSize: 13)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CustomOrderCard(
                          emoji: '🎂',
                          title: 'Custom Cake',
                          subtitle: 'Design your\ndream cake',
                          onTap: () => onCustomOrder('Cake'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _CustomOrderCard(
                          emoji: '🧁',
                          title: 'Custom Cupcake',
                          subtitle: 'Build your own\ncupcake set',
                          onTap: () => onCustomOrder('Cupcake'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Product list header with item count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🎂 Our Products',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkChoco)),
                  if (!isLoading)
                    Text('${products.length} items',
                        style: const TextStyle(
                            color: AppTheme.caramel,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          // Shows a spinner while loading, empty state, or the product grid
          if (isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppTheme.chocolate),
                ),
              ),
            )
          else if (products.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Text('🍰', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No products yet',
                          style: TextStyle(
                              color: AppTheme.chocolate.withOpacity(0.4),
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ProductCard(
                    product: products[i],
                    onAddToCart: onAddToCart,
                  ),
                  childCount: products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// Tappable banner card for placing a custom cake or cupcake order
class _CustomOrderCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CustomOrderCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.chocolateGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppTheme.chocolate.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    height: 1.4)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppTheme.gold, borderRadius: BorderRadius.circular(8)),
              child: const Text('Order Now →',
                  style: TextStyle(
                      color: AppTheme.darkChoco,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

// A single product card shown in the grid — tap it to see full details
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final ValueChanged<CartItem> onAddToCart;

  const _ProductCard({
    required this.product,
    required this.onAddToCart,
  });

  // Opens the product detail screen when the card is tapped
  void _showProductDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProductDetailScreen(
          product: product,
          onAddToCart: (item) {
            onAddToCart(item);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Text('🛍️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${product.productName} added to cart!',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.chocolate,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: AppTheme.chocolate.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image — shows a cake emoji if no image is available
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: SizedBox(
                width: double.infinity,
                height: 110,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        '${ApiService.baseUrl}${product.imageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.blush.withOpacity(0.4),
                          child: const Center(
                              child:
                                  Text('🎂', style: TextStyle(fontSize: 40))),
                        ),
                      )
                    : Container(
                        color: AppTheme.blush.withOpacity(0.4),
                        child: const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 40))),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.productName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkChoco,
                            height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(product.description,
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.chocolate.withOpacity(0.5),
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₱${product.price.toInt()}',
                            style: const TextStyle(
                                color: AppTheme.caramel,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: AppTheme.chocolate,
                              borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// PRODUCT DETAIL SCREEN
//
// Full-screen view of a product with quantity picker and order buttons
class _ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final ValueChanged<CartItem> onAddToCart;

  const _ProductDetailScreen({
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<_ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<_ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // Product image with a back button and a fade at the bottom
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 300,
                child: hasImage
                    ? Image.network(
                        '${ApiService.baseUrl}${product.imageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.blush.withOpacity(0.4),
                          child: const Center(
                              child:
                                  Text('🎂', style: TextStyle(fontSize: 80))),
                        ),
                      )
                    : Container(
                        color: AppTheme.blush.withOpacity(0.4),
                        child: const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 80))),
                      ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppTheme.cream,
                        AppTheme.cream.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppTheme.darkChoco),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.productName,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkChoco,
                              height: 1.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.chocolate.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₱${product.price.toInt()}',
                          style: const TextStyle(
                              color: AppTheme.caramel,
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.chocolate.withOpacity(0.65),
                        height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: AppTheme.roseDust.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkChoco)),
                      Row(
                        children: [
                          _QBtn(
                            icon: Icons.remove,
                            onTap: () {
                              if (_qty > 1) setState(() => _qty--);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text('$_qty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: AppTheme.darkChoco)),
                          ),
                          _QBtn(
                              icon: Icons.add,
                              filled: true,
                              onTap: () => setState(() => _qty++)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.chocolate.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal',
                            style: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text(
                          '₱${(product.price * _qty).toInt()}',
                          style: const TextStyle(
                              color: AppTheme.caramel,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom bar with "Add to Cart" and "Order Now" buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.chocolate.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final item = CartItem.regular(
                          product: product,
                          quantity: _qty,
                          deliveryDate: '',
                          deliveryTime: '',
                          deliveryAddress: '',
                          specialNotes: null,
                          paymentMethod: '',
                          fulfillmentType: '',
                          meetupPlace: null,
                        );
                        widget.onAddToCart(item);
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.chocolate.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.chocolate.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shopping_bag_outlined,
                                color: AppTheme.chocolate, size: 20),
                            SizedBox(width: 8),
                            Text('Add to Cart',
                                style: TextStyle(
                                    color: AppTheme.chocolate,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _OrderFormScreen(
                              product: product,
                              initialQty: _qty,
                              onConfirm: (item) async {
                                final userId = int.tryParse(
                                        UserSession.instance.currentUser?.id ??
                                            '0') ??
                                    0;
                                final result = await ApiService.createOrder(
                                  userId: userId,
                                  productId: item.product!.productId,
                                  quantity: item.quantity,
                                  totalPrice: item.lineTotal,
                                  deliveryDate: item.deliveryDate ?? '',
                                  deliveryTime: item.deliveryTime ?? '',
                                  deliveryAddress: item.deliveryAddress ?? '',
                                  specialNotes: item.specialNotes,
                                  paymentMethod: item.paymentMethod ?? 'COD',
                                  fulfillmentType:
                                      item.fulfillmentType ?? 'Delivery',
                                  meetupPlace: item.meetupPlace,
                                );

                                if (!context.mounted) return;
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Text(
                                          result['success'] == true
                                              ? '🎉'
                                              : '❌',
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            result['success'] == true
                                                ? 'Order placed! Check My Orders to track it.'
                                                : result['message'] ??
                                                    'Failed to place order.',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: result['success'] == true
                                        ? Colors.green.shade600
                                        : Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppTheme.chocolateGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.chocolate.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.bolt_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text('Order Now',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//
// ORDER FORM SCREEN
//
// Form screen where the user fills in delivery details before placing an order
class _OrderFormScreen extends StatefulWidget {
  final ProductModel product;
  final int initialQty;
  final Future<void> Function(CartItem) onConfirm;

  const _OrderFormScreen({
    required this.product,
    required this.initialQty,
    required this.onConfirm,
  });

  @override
  State<_OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<_OrderFormScreen> {
  late int _qty;
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;
  final _addressCtrl = TextEditingController();
  final _meetupCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _fulfillmentType = 'Delivery';
  String _paymentMethod = 'COD';
  bool _isPlacing = false;

  // Sets initial quantity and auto-fills the delivery address
  @override
  void initState() {
    super.initState();
    _qty = widget.initialQty;
    final defaultAddress = UserSession.instance.selectedDeliveryAddress;
    if (defaultAddress.isNotEmpty) {
      _addressCtrl.text = defaultAddress;
    }
  }

  // Shows a readable date or a placeholder if none is picked yet
  String get _formattedDate => _deliveryDate == null
      ? 'Select date'
      : '${_deliveryDate!.year}-${_deliveryDate!.month.toString().padLeft(2, '0')}-${_deliveryDate!.day.toString().padLeft(2, '0')}';

  // Shows a readable time or a placeholder if none is picked yet
  String get _formattedTime =>
      _deliveryTime == null ? 'Select time' : _deliveryTime!.format(context);

  // Opens the date picker
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.chocolate)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  // Opens the time picker
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.chocolate)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deliveryTime = picked);
  }

  // Validates the form and sends the order if everything is filled in
  Future<void> _confirmOrder() async {
    if (_isPlacing) return;
    if (!_formKey.currentState!.validate()) return;
    if (_deliveryDate == null) {
      _snack('Please select a date');
      return;
    }
    if (_deliveryTime == null) {
      _snack('Please select a time');
      return;
    }
    if (_fulfillmentType == 'Delivery' && _addressCtrl.text.trim().isEmpty) {
      _snack('Please enter delivery address');
      return;
    }
    if (_fulfillmentType == 'Pickup' && _meetupCtrl.text.trim().isEmpty) {
      _snack('Please enter meetup/pickup place');
      return;
    }

    final item = CartItem.regular(
      product: widget.product,
      quantity: _qty,
      deliveryDate: _formattedDate,
      deliveryTime: _formattedTime,
      deliveryAddress: _fulfillmentType == 'Delivery'
          ? _addressCtrl.text.trim()
          : _meetupCtrl.text.trim(),
      specialNotes: _notesCtrl.text.trim(),
      paymentMethod: _paymentMethod,
      fulfillmentType: _fulfillmentType,
      meetupPlace:
          _fulfillmentType == 'Pickup' ? _meetupCtrl.text.trim() : null,
    );

    setState(() => _isPlacing = true);
    await widget.onConfirm(item);
    if (mounted) setState(() => _isPlacing = false);
  }

  // Shows a red error snackbar at the bottom of the screen
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // Cleans up all text controllers when the screen is closed
  @override
  void dispose() {
    _addressCtrl.dispose();
    _meetupCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // Header showing the product info and quantity adjuster
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: AppTheme.cream,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: AppTheme.darkChoco),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Order Details',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkChoco)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: widget.product.imageUrl != null &&
                                    widget.product.imageUrl!.isNotEmpty
                                ? Image.network(
                                    '${ApiService.baseUrl}${widget.product.imageUrl}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppTheme.blush.withOpacity(0.4),
                                      child: const Center(
                                          child: Text('🎂',
                                              style: TextStyle(fontSize: 28))),
                                    ),
                                  )
                                : Container(
                                    color: AppTheme.blush.withOpacity(0.4),
                                    child: const Center(
                                        child: Text('🎂',
                                            style: TextStyle(fontSize: 28))),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.product.productName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppTheme.darkChoco)),
                              const SizedBox(height: 4),
                              Text('₱${widget.product.price.toInt()} each',
                                  style: const TextStyle(
                                      color: AppTheme.caramel,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _QBtn(
                                icon: Icons.remove,
                                onTap: () {
                                  if (_qty > 1) setState(() => _qty--);
                                }),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$_qty',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: AppTheme.darkChoco)),
                            ),
                            _QBtn(
                                icon: Icons.add,
                                filled: true,
                                onTap: () => setState(() => _qty++)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: AppTheme.cream,
                    child: Text(
                      'Subtotal: ₱${(widget.product.price * _qty).toInt()}',
                      style: const TextStyle(
                          color: AppTheme.caramel,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('📦 How do you want it?'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ChoiceChip(
                            label: '🚚 Delivery',
                            selected: _fulfillmentType == 'Delivery',
                            onTap: () =>
                                setState(() => _fulfillmentType = 'Delivery'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChoiceChip(
                            label: '🤝 Pickup',
                            selected: _fulfillmentType == 'Pickup',
                            onTap: () =>
                                setState(() => _fulfillmentType = 'Pickup'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Address field changes based on delivery or pickup
                    if (_fulfillmentType == 'Delivery') ...[
                      _SectionLabel('📍 Delivery Address'),
                      const SizedBox(height: 8),
                      _FormCard(
                        child: TextFormField(
                          controller: _addressCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Enter your delivery address...',
                            hintStyle: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.4),
                                fontSize: 14),
                            prefixIcon: Icon(Icons.location_on_outlined,
                                color: AppTheme.caramel.withOpacity(0.7),
                                size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          validator: (v) => _fulfillmentType == 'Delivery' &&
                                  (v == null || v.isEmpty)
                              ? 'Address is required'
                              : null,
                        ),
                      ),
                    ] else ...[
                      _SectionLabel('📍 Meetup / Pickup Place'),
                      const SizedBox(height: 8),
                      _FormCard(
                        child: TextFormField(
                          controller: _meetupCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'Enter where you will pick up your order...',
                            hintStyle: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.4),
                                fontSize: 14),
                            prefixIcon: Icon(Icons.storefront_outlined,
                                color: AppTheme.caramel.withOpacity(0.7),
                                size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          validator: (v) => _fulfillmentType == 'Pickup' &&
                                  (v == null || v.isEmpty)
                              ? 'Pickup place is required'
                              : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SectionLabel('📅 Schedule'),
                    const SizedBox(height: 8),
                    _FormCard(
                      child: Column(
                        children: [
                          _TapField(
                            label: 'Date',
                            value: _formattedDate,
                            icon: Icons.calendar_today_outlined,
                            onTap: _pickDate,
                          ),
                          const Divider(height: 1, color: Color(0xFFEEE0D4)),
                          const SizedBox(height: 4),
                          _TapField(
                            label: 'Time',
                            value: _formattedTime,
                            icon: Icons.access_time_outlined,
                            onTap: _pickTime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel('📝 Special Notes (optional)'),
                    const SizedBox(height: 8),
                    _FormCard(
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Any special requests...',
                          hintStyle: TextStyle(
                              color: AppTheme.chocolate.withOpacity(0.4),
                              fontSize: 14),
                          prefixIcon: Icon(Icons.note_outlined,
                              color: AppTheme.caramel.withOpacity(0.7),
                              size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Payment method selection
                    _SectionLabel('💳 Payment Method'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ChoiceChip(
                            label: '💵 Cash on Delivery',
                            selected: _paymentMethod == 'COD',
                            onTap: () => setState(() => _paymentMethod = 'COD'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChoiceChip(
                            label: '📱 GCash',
                            selected: _paymentMethod == 'GCash',
                            onTap: () =>
                                setState(() => _paymentMethod = 'GCash'),
                          ),
                        ),
                      ],
                    ),
                    // GCash reminder shown only when GCash is selected
                    if (_paymentMethod == 'GCash') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📱', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You selected GCash. After your order is confirmed, '
                                'you can upload your GCash receipt from "My Orders" in your profile.',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Place Order button — shows a spinner while submitting
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isPlacing ? null : _confirmOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.chocolate,
                          disabledBackgroundColor:
                              AppTheme.chocolate.withOpacity(0.5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isPlacing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Place Order',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A tappable chip used to select delivery type or payment method
class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.chocolate : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppTheme.chocolate
                : AppTheme.roseDust.withOpacity(0.4),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppTheme.chocolate.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : AppTheme.darkChoco,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      ),
    );
  }
}

// Bold section title shown above each group of fields
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppTheme.darkChoco));
}

// White rounded card that wraps each form section
class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppTheme.chocolate.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: child,
      );
}

// A tappable row used for picking date and time
class _TapField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TapField(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.startsWith('Select');
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.caramel.withOpacity(0.7), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: AppTheme.chocolate.withOpacity(0.5),
                          fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          color: isPlaceholder
                              ? AppTheme.chocolate.withOpacity(0.35)
                              : AppTheme.darkChoco,
                          fontSize: 14,
                          fontWeight: isPlaceholder
                              ? FontWeight.w400
                              : FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: AppTheme.caramel.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// Small + and - buttons for adjusting quantity
class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? AppTheme.chocolate : AppTheme.cream,
          borderRadius: BorderRadius.circular(9),
          border: filled
              ? null
              : Border.all(color: AppTheme.roseDust.withOpacity(0.4)),
        ),
        child: Icon(icon,
            size: 18, color: filled ? Colors.white : AppTheme.chocolate),
      ),
    );
  }
}

//
// CART TAB
//
// Shows the user's cart with checkboxes to select items for ordering
class _CartTab extends StatefulWidget {
  final List<CartItem> cart;
  final double total;
  final String userId;
  final VoidCallback onUpdate;
  final Future<void> Function() onOrdersPlaced;

  const _CartTab({
    super.key,
    required this.cart,
    required this.total,
    required this.userId,
    required this.onUpdate,
    required this.onOrdersPlaced,
  });

  @override
  State<_CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<_CartTab> {
  bool _isPlacingOrder = false;
  final Set<int> _selectedIndices = {};

  // Triggers checkout from outside this widget (e.g. from the nav bar)
  void triggerCheckout() {
    if (!_isPlacingOrder && widget.cart.isNotEmpty) {
      _handlePlaceSelected();
    }
  }

  // Opens the order form for each selected item one by one
  Future<void> _handlePlaceSelected() async {
    final toPlace = _selectedIndices
        .map((i) => widget.cart[i])
        .where((item) => !item.isCustom)
        .toList();

    if (toPlace.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select at least one item to order.',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }

    // Process each selected item one by one through the order form
    int success = 0;
    int failed = 0;
    final userId = int.tryParse(widget.userId) ?? 0;

    for (final item in toPlace) {
      // Open the order form for this item
      final confirmed = await Navigator.push<CartItem?>(
        context,
        MaterialPageRoute(
          builder: (_) => _OrderFormScreen(
            product: item.product!,
            initialQty: item.quantity,
            onConfirm: (filledItem) async {
              Navigator.pop(context, filledItem);
            },
          ),
        ),
      );

      // Skip this item if the user cancelled the form
      if (confirmed == null) continue;

      setState(() => _isPlacingOrder = true);

      final result = await ApiService.createOrder(
        userId: userId,
        productId: confirmed.product!.productId,
        quantity: confirmed.quantity,
        totalPrice: confirmed.lineTotal,
        deliveryDate: confirmed.deliveryDate ?? '',
        deliveryTime: confirmed.deliveryTime ?? '',
        deliveryAddress: confirmed.deliveryAddress ?? '',
        specialNotes: confirmed.specialNotes,
        paymentMethod: confirmed.paymentMethod ?? 'COD',
        fulfillmentType: confirmed.fulfillmentType ?? 'Delivery',
        meetupPlace: confirmed.meetupPlace,
      );

      if (result['success'] == true) {
        success++;
        // Remove from cart after a successful order
        final cartIndex = widget.cart.indexOf(item);
        if (cartIndex != -1) {
          widget.cart.removeAt(cartIndex);
          _selectedIndices.clear();
          widget.onUpdate();
          await widget.onOrdersPlaced();
        }
      } else {
        failed++;
      }

      setState(() => _isPlacingOrder = false);
    }

    if (!mounted) return;

    // Show success or failure message when all orders are done
    if (success > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$success order${success > 1 ? 's' : ''} placed! Check My Orders to track.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ));
    }

    if (failed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '$failed order${failed > 1 ? 's' : ''} failed. Please try again.',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  // Total price of only the selected items
  double get _selectedTotal => _selectedIndices
      .where((i) => i < widget.cart.length)
      .fold(0.0, (s, i) => s + widget.cart[i].lineTotal);

  @override
  Widget build(BuildContext context) {
    final regularItems = widget.cart.where((c) => !c.isCustom).toList();

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Cart 🛍️',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkChoco)),
              // Select All / Deselect All toggle
              if (regularItems.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedIndices.length == regularItems.length) {
                        _selectedIndices.clear();
                      } else {
                        _selectedIndices.clear();
                        for (int i = 0; i < widget.cart.length; i++) {
                          if (!widget.cart[i].isCustom) {
                            _selectedIndices.add(i);
                          }
                        }
                      }
                    });
                  },
                  child: Text(
                    _selectedIndices.length == regularItems.length &&
                            regularItems.isNotEmpty
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(
                        color: AppTheme.chocolate,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: widget.cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🛒', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      Text('Your cart is empty',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.chocolate.withOpacity(0.5))),
                      const SizedBox(height: 8),
                      Text('Add some sweet treats to get started!',
                          style: TextStyle(
                              color: AppTheme.chocolate.withOpacity(0.35),
                              fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.cart.length,
                  itemBuilder: (_, i) {
                    final item = widget.cart[i];
                    final isSelected = _selectedIndices.contains(i);

                    return GestureDetector(
                      onTap: item.isCustom
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIndices.remove(i);
                                } else {
                                  _selectedIndices.add(i);
                                }
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.chocolate
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.chocolate.withOpacity(0.06),
                                blurRadius: 8)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selection indicator shown at the top of each cart item
                            if (!item.isCustom)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.chocolate.withOpacity(0.08)
                                      : AppTheme.cream.withOpacity(0.5),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AppTheme.chocolate
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.chocolate
                                              : AppTheme.roseDust
                                                  .withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 12)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isSelected
                                          ? 'Selected for order'
                                          : 'Tap to select',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected
                                            ? AppTheme.chocolate
                                            : AppTheme.chocolate
                                                .withOpacity(0.4),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Item image or emoji fallback
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: !item.isCustom &&
                                                  item.product?.imageUrl !=
                                                      null &&
                                                  item.product!.imageUrl!
                                                      .isNotEmpty
                                              ? Image.network(
                                                  '${ApiService.baseUrl}${item.product!.imageUrl}',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                    color: AppTheme.blush
                                                        .withOpacity(0.3),
                                                    child: Center(
                                                        child: Text(
                                                            item.displayEmoji,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        24))),
                                                  ),
                                                )
                                              : Container(
                                                  color: AppTheme.blush
                                                      .withOpacity(0.3),
                                                  child: Center(
                                                      child: Text(
                                                          item.displayEmoji,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      24))),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.displayName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    color: AppTheme.darkChoco)),
                                            const SizedBox(height: 3),
                                            if (!item.isCustom)
                                              Text('₱${item.lineTotal.toInt()}',
                                                  style: const TextStyle(
                                                      color: AppTheme.caramel,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                      // X button to remove the item from the cart
                                      GestureDetector(
                                        onTap: () {
                                          _selectedIndices.remove(i);
                                          widget.cart.removeAt(i);
                                          widget.onUpdate();
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: const Icon(Icons.close,
                                              size: 16,
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Quantity adjuster for regular (non-custom) items
                                  if (!item.isCustom) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _QBtn(
                                          icon: Icons.remove,
                                          onTap: () {
                                            if (item.quantity > 1) {
                                              item.quantity -= 1;
                                              widget.onUpdate();
                                            } else {
                                              _selectedIndices.remove(i);
                                              widget.cart.removeAt(i);
                                              widget.onUpdate();
                                            }
                                          },
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14),
                                          child: Text('${item.quantity}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                  color: AppTheme.darkChoco)),
                                        ),
                                        _QBtn(
                                            icon: Icons.add,
                                            filled: true,
                                            onTap: () {
                                              item.quantity += 1;
                                              widget.onUpdate();
                                            }),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Bottom bar showing selected total and the Place Orders button
        if (widget.cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.chocolate.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedIndices.length} of ${regularItems.length} item${regularItems.length != 1 ? 's' : ''} selected',
                        style: TextStyle(
                            color: AppTheme.chocolate.withOpacity(0.6),
                            fontSize: 13),
                      ),
                      if (_selectedTotal > 0)
                        Text('₱${_selectedTotal.toInt()}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkChoco))
                      else
                        Text('Select items above',
                            style: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.5),
                                fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_isPlacingOrder || _selectedIndices.isEmpty)
                          ? null
                          : _handlePlaceSelected,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.chocolate,
                        disabledBackgroundColor:
                            AppTheme.chocolate.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _selectedIndices.isEmpty
                                  ? 'Select items to order'
                                  : 'Place ${_selectedIndices.length} Order${_selectedIndices.length != 1 ? 's' : ''}  🧁',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

//
// PROFILE TAB
//
// Shows the user's profile picture, info, and menu options
class _ProfileTab extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onLogout;
  final VoidCallback onUserUpdated;

  const _ProfileTab(
      {required this.user,
      required this.onLogout,
      required this.onUserUpdated});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isUploadingPhoto = false;

  // Picks a new photo from the gallery and uploads it to the server
  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;
    final userId = int.tryParse(widget.user?.id ?? '') ?? 0;
    if (userId == 0) return;
    setState(() => _isUploadingPhoto = true);
    final result = await ApiService.updateProfilePicture(
        userId: userId, imageFile: picked);
    setState(() => _isUploadingPhoto = false);
    if (!mounted) return;
    if (result['success'] == true) {
      UserSession.instance.updateProfilePicture(result['imageUrl']);
      widget.onUserUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Text('📸', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Text('Profile photo updated!',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: AppTheme.chocolate,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final name = user?.name ?? 'Guest';
    final email = user?.email ?? '';
    final phone = user?.phone;
    final profilePicUrl = user?.profilePicture;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header with avatar, name, email, and phone
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                bottom: 36,
                left: 24,
                right: 24),
            decoration: const BoxDecoration(
              gradient: AppTheme.chocolateGradient,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40)),
            ),
            child: Column(
              children: [
                // Avatar with a camera button to change the photo
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                            color: AppTheme.gold.withOpacity(0.5), width: 2),
                      ),
                      child: ClipOval(
                        child: _isUploadingPhoto
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : profilePicUrl != null && profilePicUrl.isNotEmpty
                                ? Image.network(
                                    '${ApiService.baseUrl}$profilePicUrl',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                        child: Text(user?.avatarEmoji ?? '👤',
                                            style:
                                                const TextStyle(fontSize: 44))),
                                  )
                                : Center(
                                    child: Text(user?.avatarEmoji ?? '👤',
                                        style: const TextStyle(fontSize: 44))),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isUploadingPhoto ? null : _changeProfilePicture,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: AppTheme.darkChoco, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _changeProfilePicture,
                  child: Text(
                    _isUploadingPhoto ? 'Uploading...' : 'Change Photo',
                    style: TextStyle(
                        color: AppTheme.gold.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.gold.withOpacity(0.85)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(email,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 14)),
                if (phone != null) ...[
                  const SizedBox(height: 2),
                  Text(phone,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45), fontSize: 12)),
                ],
              ],
            ),
          ),
          // Menu tiles linking to orders, addresses, and settings
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'My Orders',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyOrdersScreen()))),
                _ProfileTile(
                    icon: Icons.cake_outlined,
                    label: 'My Custom Orders',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyCustomOrdersScreen()))),
                _ProfileTile(
                    icon: Icons.location_on_outlined,
                    label: 'Delivery Addresses',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DeliveryAddressesScreen()))),
                _ProfileTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => NotificationsScreen()))),
                _ProfileTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen()))),
                const SizedBox(height: 8),
                _ProfileTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    onTap: widget.onLogout,
                    isDestructive: true),
                const SizedBox(height: 30),
                Center(
                  child: Text('Sweet Cengsations v1.0.0 ✦',
                      style: TextStyle(
                          color: AppTheme.chocolate.withOpacity(0.3),
                          fontSize: 12,
                          letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// A single row in the profile menu that navigates to another screen
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : AppTheme.darkChoco;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppTheme.chocolate.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isDestructive ? Colors.red.withOpacity(0.08) : AppTheme.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppTheme.chocolate.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

//
// BOTTOM NAV
//
// Bottom navigation bar with Home, Cart, and Profile tabs
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _BottomNav(
      {required this.currentIndex,
      required this.cartCount,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom, top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: AppTheme.chocolate.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              current: currentIndex,
              onTap: onTap),
          _NavItemCart(
              cartCount: cartCount,
              index: 1,
              current: currentIndex,
              onTap: onTap),
          _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              index: 2,
              current: currentIndex,
              onTap: onTap),
        ],
      ),
    );
  }
}

// A single nav bar icon with a label — highlights when active
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.index,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive
                    ? AppTheme.chocolate
                    : AppTheme.chocolate.withOpacity(0.35),
                size: 26),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isActive
                        ? AppTheme.chocolate
                        : AppTheme.chocolate.withOpacity(0.35),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// Cart nav icon with a badge showing how many items are in the cart
class _NavItemCart extends StatelessWidget {
  final int cartCount;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItemCart(
      {required this.cartCount,
      required this.index,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                    isActive
                        ? Icons.shopping_bag_rounded
                        : Icons.shopping_bag_outlined,
                    color: isActive
                        ? AppTheme.chocolate
                        : AppTheme.chocolate.withOpacity(0.35),
                    size: 26),
                // Badge showing cart item count
                if (cartCount > 0)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                          color: AppTheme.caramel, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$cartCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text('Cart',
                style: TextStyle(
                    fontSize: 10,
                    color: isActive
                        ? AppTheme.chocolate
                        : AppTheme.chocolate.withOpacity(0.35),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
