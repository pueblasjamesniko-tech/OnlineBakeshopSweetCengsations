import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/product_model.dart';
import '../../../models/cart_item.dart';
import '../../../models/user_session.dart';
import '../../../models/UserModel.dart';
import '../../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';
import 'custom_order_screen.dart';
import 'my_orders_screen.dart';
import 'my_custom_orders_screen.dart';
import 'help_support_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    _initLoad();
  }

  Future<void> _initLoad() async {
    await _loadPersistedCart();
    _loadProducts();
  }

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

  Future<void> _persistCart() async {
    if (_userId.isNotEmpty) {
      await ApiService.saveCart(_userId, _cart);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    final products = await ApiService.getAllProducts();
    setState(() {
      _products = products;
      _isLoadingProducts = false;
    });
  }

  int get _cartCount => _cart.fold(0, (s, i) => s + i.quantity);
  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.lineTotal);

  void _addToCart(CartItem item) {
    setState(() {
      if (!item.isCustom) {
        final existing = _cart.where(
          (c) =>
              !c.isCustom &&
              c.product?.productId == item.product?.productId &&
              c.deliveryDate == item.deliveryDate &&
              c.deliveryAddress == item.deliveryAddress,
        );
        if (existing.isNotEmpty) {
          existing.first.quantity += item.quantity;
        } else {
          _cart.add(item);
        }
      }
    });
    _persistCart();
  }

  void _placeNow(CartItem item) {
    _addToCart(item);
    setState(() => _navIndex = 1);
    Future.delayed(const Duration(milliseconds: 350), () {
      _cartTabKey.currentState?.triggerCheckout();
    });
  }

  void _handleLogout() {
    ApiService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
            // 0 — Home
            _HomeTab(
              products: _products,
              isLoading: _isLoadingProducts,
              cartCount: _cartCount,
              userName: UserSession.instance.firstName,
              onAddToCart: _addToCart,
              onPlaceNow: _placeNow,
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
                                  'Custom order submitted! Check My Custom Orders in Profile to track it.',
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

            // 1 — Cart
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

            // 2 — Profile
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

// ═══════════════════════════════════════════════════════════════
// HOME TAB
// ═══════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final List<ProductModel> products;
  final bool isLoading;
  final int cartCount;
  final String userName;
  final ValueChanged<CartItem> onAddToCart;
  final ValueChanged<CartItem> onPlaceNow;
  final VoidCallback onCartTap;
  final ValueChanged<String> onCustomOrder;
  final Future<void> Function() onRefresh;

  const _HomeTab({
    required this.products,
    required this.isLoading,
    required this.cartCount,
    required this.userName,
    required this.onAddToCart,
    required this.onPlaceNow,
    required this.onCartTap,
    required this.onCustomOrder,
    required this.onRefresh,
  });

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
          // ── Header ──────────────────────────────────────────
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
                      // ── Real logo + brand name ──────────────
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/bakeshop_logo.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sweet Cengsations',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '✦ Artisan Bakeshop ✦',
                                style: TextStyle(
                                  color: AppTheme.gold.withOpacity(0.85),
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // ── Cart icon ───────────────────────────
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
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
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
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$cartCount',
                                      style: const TextStyle(
                                        color: AppTheme.darkChoco,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_getGreeting()}, $userName! 🌅',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'What sweet treat\nare you craving?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Custom Order Banner ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎨 Customize Your Order',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkChoco,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Design your dream cake or cupcake!',
                    style: TextStyle(
                      color: AppTheme.chocolate.withOpacity(0.55),
                      fontSize: 13,
                    ),
                  ),
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

          // ── Products Header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🎂 Our Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkChoco,
                    ),
                  ),
                  if (!isLoading)
                    Text(
                      '${products.length} items',
                      style: const TextStyle(
                        color: AppTheme.caramel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Product Grid ─────────────────────────────────────
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
                      Text(
                        'No products yet',
                        style: TextStyle(
                          color: AppTheme.chocolate.withOpacity(0.4),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                    onPlaceNow: onPlaceNow,
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

// ── Custom Order Banner Card ──────────────────────────────────────────────────
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
              offset: const Offset(0, 5),
            ),
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
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Order Now →',
                style: TextStyle(
                  color: AppTheme.darkChoco,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final ValueChanged<CartItem> onAddToCart;
  final ValueChanged<CartItem> onPlaceNow;

  const _ProductCard({
    required this.product,
    required this.onAddToCart,
    required this.onPlaceNow,
  });

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        product: product,
        onAddToCart: onAddToCart,
        onPlaceNow: onPlaceNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.chocolate.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            child: Text('🎂', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.blush.withOpacity(0.4),
                        child: const Center(
                          child: Text('🎂', style: TextStyle(fontSize: 40)),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkChoco,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.chocolate.withOpacity(0.5),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${product.price.toInt()}',
                          style: const TextStyle(
                            color: AppTheme.caramel,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showDetail(context),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.chocolate,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
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

// ═══════════════════════════════════════════════════════════════
// PRODUCT DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════
class _ProductDetailSheet extends StatefulWidget {
  final ProductModel product;
  final ValueChanged<CartItem> onAddToCart;
  final ValueChanged<CartItem> onPlaceNow;

  const _ProductDetailSheet({
    required this.product,
    required this.onAddToCart,
    required this.onPlaceNow,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  int _qty = 1;
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _showOrderForm = false;
  bool _placeDirectly = false;
  final _formKey = GlobalKey<FormState>();

  String get _formattedDate => _deliveryDate == null
      ? 'Select date'
      : '${_deliveryDate!.year}-${_deliveryDate!.month.toString().padLeft(2, '0')}-${_deliveryDate!.day.toString().padLeft(2, '0')}';

  String get _formattedTime =>
      _deliveryTime == null ? 'Select time' : _deliveryTime!.format(context);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.chocolate),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.chocolate),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deliveryTime = picked);
  }

  void _confirmAction() {
    if (!_formKey.currentState!.validate()) return;
    if (_deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery date')),
      );
      return;
    }
    if (_deliveryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery time')),
      );
      return;
    }

    final item = CartItem.regular(
      product: widget.product,
      quantity: _qty,
      deliveryDate: _formattedDate,
      deliveryTime: _formattedTime,
      deliveryAddress: _addressCtrl.text.trim(),
      specialNotes: _notesCtrl.text.trim(),
    );

    Navigator.pop(context);

    if (_placeDirectly) {
      widget.onPlaceNow(item);
    } else {
      widget.onAddToCart(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🛍️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.product.productName} added to cart!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
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
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.6,
      maxChildSize: 1.0,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 280,
                  child: widget.product.imageUrl != null &&
                          widget.product.imageUrl!.isNotEmpty
                      ? Image.network(
                          '${ApiService.baseUrl}${widget.product.imageUrl}',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 280,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.blush.withOpacity(0.4),
                            child: const Center(
                              child: Text('🎂', style: TextStyle(fontSize: 80)),
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.blush.withOpacity(0.4),
                          child: const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 80)),
                          ),
                        ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.chocolate,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₱${widget.product.price.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.productName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkChoco,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description,
                      style: TextStyle(
                        color: AppTheme.chocolate.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkChoco,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        _QtyControl(
                          qty: _qty,
                          onMinus: () {
                            if (_qty > 1) setState(() => _qty--);
                          },
                          onPlus: () => setState(() => _qty++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Subtotal: ₱${(widget.product.price * _qty).toInt()}',
                      style: const TextStyle(
                        color: AppTheme.caramel,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEE0D4)),
                    const SizedBox(height: 16),
                    if (!_showOrderForm) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() {
                            _placeDirectly = false;
                            _showOrderForm = true;
                          }),
                          icon:
                              const Icon(Icons.shopping_bag_outlined, size: 20),
                          label: const Text('Add to Cart',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.chocolate,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() {
                            _placeDirectly = true;
                            _showOrderForm = true;
                          }),
                          icon: const Icon(Icons.flash_on_rounded, size: 20),
                          label: const Text('Place Order Now',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.caramel,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _placeDirectly
                                  ? AppTheme.caramel.withOpacity(0.12)
                                  : AppTheme.chocolate.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _placeDirectly
                                      ? Icons.flash_on_rounded
                                      : Icons.shopping_bag_outlined,
                                  size: 14,
                                  color: _placeDirectly
                                      ? AppTheme.caramel
                                      : AppTheme.chocolate,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _placeDirectly
                                      ? 'Place Order Now'
                                      : 'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _placeDirectly
                                        ? AppTheme.caramel
                                        : AppTheme.chocolate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Delivery Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkChoco,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _TapField(
                              label: 'Delivery Date',
                              value: _formattedDate,
                              icon: Icons.calendar_today_outlined,
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: 12),
                            _TapField(
                              label: 'Delivery Time',
                              value: _formattedTime,
                              icon: Icons.access_time_outlined,
                              onTap: _pickTime,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Delivery Address',
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  color: AppTheme.caramel.withOpacity(0.7),
                                  size: 20,
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Address is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Special Notes (optional)',
                                prefixIcon: Icon(
                                  Icons.note_outlined,
                                  color: AppTheme.caramel.withOpacity(0.7),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        setState(() => _showOrderForm = false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.chocolate,
                                      side: const BorderSide(
                                          color: AppTheme.chocolate),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: const Text('Back'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _confirmAction,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _placeDirectly
                                          ? AppTheme.caramel
                                          : AppTheme.chocolate,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      _placeDirectly
                                          ? '⚡  Confirm & Order'
                                          : '🛍️  Confirm & Add',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
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

// ── Tap Field ─────────────────────────────────────────────────────────────────
class _TapField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TapField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.startsWith('Select');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.warmWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.roseDust.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.caramel.withOpacity(0.7), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.chocolate.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: isPlaceholder
                          ? AppTheme.chocolate.withOpacity(0.35)
                          : AppTheme.darkChoco,
                      fontSize: 14,
                      fontWeight:
                          isPlaceholder ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: AppTheme.caramel.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Qty Control ───────────────────────────────────────────────────────────────
class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtyControl({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QBtn(icon: Icons.remove, onTap: onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '$qty',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.darkChoco,
            ),
          ),
        ),
        _QBtn(icon: Icons.add, filled: true, onTap: onPlus),
      ],
    );
  }
}

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

// ═══════════════════════════════════════════════════════════════
// CART TAB
// ═══════════════════════════════════════════════════════════════
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

  void triggerCheckout() {
    if (!_isPlacingOrder && widget.cart.isNotEmpty) {
      _placeAllOrders();
    }
  }

  Future<void> _placeAllOrders() async {
    if (widget.cart.isEmpty) return;
    setState(() => _isPlacingOrder = true);

    int success = 0;
    int failed = 0;
    final userId = int.tryParse(widget.userId) ?? 0;

    for (final item in List.from(widget.cart)) {
      if (item.isCustom) continue;

      final result = await ApiService.createOrder(
        userId: userId,
        productId: item.product!.productId,
        quantity: item.quantity,
        totalPrice: item.lineTotal,
        deliveryDate: item.deliveryDate ?? '',
        deliveryTime: item.deliveryTime ?? '',
        deliveryAddress: item.deliveryAddress ?? '',
        specialNotes: item.specialNotes,
      );

      if (result['success'] == true) {
        success++;
      } else {
        failed++;
      }
    }

    setState(() => _isPlacingOrder = false);
    if (!mounted) return;

    if (failed == 0 && success > 0) {
      widget.cart.clear();
      widget.onUpdate();
      await widget.onOrdersPlaced();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$success order${success > 1 ? 's' : ''} placed! Check My Orders in Profile to track.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (success == 0 && failed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No orders to place.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$success placed, $failed failed. Please try again.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'My Cart 🛍️',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkChoco,
              ),
            ),
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
                      Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.chocolate.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add some sweet treats to get started!',
                        style: TextStyle(
                          color: AppTheme.chocolate.withOpacity(0.35),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.cart.length,
                  itemBuilder: (_, i) {
                    final item = widget.cart[i];
                    return _CartItemCard(
                      item: item,
                      onRemove: () {
                        widget.cart.removeAt(i);
                        widget.onUpdate();
                      },
                      onQtyChanged: (newQty) {
                        item.quantity = newQty;
                        widget.onUpdate();
                      },
                    );
                  },
                ),
        ),
        if (widget.cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.chocolate.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
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
                        '${widget.cart.length} item${widget.cart.length > 1 ? 's' : ''} in cart',
                        style: TextStyle(
                          color: AppTheme.chocolate.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      if (widget.total > 0)
                        Text(
                          '₱${widget.total.toInt()}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkChoco,
                          ),
                        )
                      else
                        Text(
                          'Price pending',
                          style: TextStyle(
                            color: AppTheme.chocolate.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : _placeAllOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.chocolate,
                        disabledBackgroundColor:
                            AppTheme.chocolate.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Place Order  🧁',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

// ── Cart Item Card ────────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChanged;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: !item.isCustom &&
                          item.product?.imageUrl != null &&
                          item.product!.imageUrl!.isNotEmpty
                      ? Image.network(
                          '${ApiService.baseUrl}${item.product!.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.blush.withOpacity(0.3),
                            child: Center(
                              child: Text(
                                item.displayEmoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.blush.withOpacity(0.3),
                          child: Center(
                            child: Text(
                              item.displayEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.darkChoco,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (item.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '⏳ Awaiting price quote',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.caramel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        '₱${item.lineTotal.toInt()}',
                        style: const TextStyle(
                          color: AppTheme.caramel,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close,
                      size: 16, color: Colors.redAccent),
                ),
              ),
            ],
          ),
          if (!item.isCustom && item.deliveryDate != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppTheme.chocolate.withOpacity(0.5)),
                      const SizedBox(width: 6),
                      Text(
                        '${item.deliveryDate} at ${item.deliveryTime}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.chocolate.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  if (item.deliveryAddress != null &&
                      item.deliveryAddress!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12,
                            color: AppTheme.chocolate.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.deliveryAddress!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.chocolate.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (!item.isCustom) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _QtyControl(
                  qty: item.quantity,
                  onMinus: () {
                    if (item.quantity > 1) {
                      onQtyChanged(item.quantity - 1);
                    } else {
                      onRemove();
                    }
                  },
                  onPlus: () => onQtyChanged(item.quantity + 1),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROFILE TAB
// ═══════════════════════════════════════════════════════════════
class _ProfileTab extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onLogout;
  final VoidCallback onUserUpdated;

  const _ProfileTab({
    required this.user,
    required this.onLogout,
    required this.onUserUpdated,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isUploadingPhoto = false;

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return; // picked is already an XFile

    final userId = int.tryParse(widget.user?.id ?? '') ?? 0;
    if (userId == 0) return;

    setState(() => _isUploadingPhoto = true);

    final result = await ApiService.updateProfilePicture(
      userId: userId,
      imageFile: picked, // ← pass XFile directly, not picked.path
    );

    setState(() => _isUploadingPhoto = false);

    if (!mounted) return;

    if (result['success'] == true) {
      UserSession.instance.updateProfilePicture(result['imageUrl']);
      widget.onUserUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Text('📸', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Text(
                'Profile photo updated!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppTheme.chocolate,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Upload failed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 36,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: AppTheme.chocolateGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                // ── Avatar with camera overlay ──────────────
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
                          color: AppTheme.gold.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _isUploadingPhoto
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : profilePicUrl != null && profilePicUrl.isNotEmpty
                                ? Image.network(
                                    '${ApiService.baseUrl}$profilePicUrl',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        user?.avatarEmoji ?? '👤',
                                        style: const TextStyle(fontSize: 44),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      user?.avatarEmoji ?? '👤',
                                      style: const TextStyle(fontSize: 44),
                                    ),
                                  ),
                      ),
                    ),
                    // ── Camera button ────────────────────────
                    GestureDetector(
                      onTap: _isUploadingPhoto ? null : _changeProfilePicture,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppTheme.darkChoco,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Change Photo text ────────────────────────
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _changeProfilePicture,
                  child: Text(
                    _isUploadingPhoto ? 'Uploading...' : 'Change Photo',
                    style: TextStyle(
                      color: AppTheme.gold.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.gold.withOpacity(0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  ),
                ),
                _ProfileTile(
                  icon: Icons.cake_outlined,
                  label: 'My Custom Orders',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyCustomOrdersScreen()),
                  ),
                ),
                _ProfileTile(
                  icon: Icons.location_on_outlined,
                  label: 'Delivery Addresses',
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                _ProfileTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  onTap: widget.onLogout,
                  isDestructive: true,
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'Sweet Cengsations v1.0.0 ✦',
                    style: TextStyle(
                      color: AppTheme.chocolate.withOpacity(0.3),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Tile ──────────────────────────────────────────────────────────────
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : AppTheme.darkChoco;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.05),
            blurRadius: 8,
          ),
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
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppTheme.chocolate.withOpacity(0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM NAV
// ═══════════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

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
            offset: const Offset(0, -4),
          ),
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
            onTap: onTap,
          ),
          _NavItemCart(
            cartCount: cartCount,
            index: 1,
            current: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            index: 2,
            current: currentIndex,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

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
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? AppTheme.chocolate
                  : AppTheme.chocolate.withOpacity(0.35),
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? AppTheme.chocolate
                    : AppTheme.chocolate.withOpacity(0.35),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemCart extends StatelessWidget {
  final int cartCount;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItemCart({
    required this.cartCount,
    required this.index,
    required this.current,
    required this.onTap,
  });

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
                  size: 26,
                ),
                if (cartCount > 0)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppTheme.caramel,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Cart',
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? AppTheme.chocolate
                    : AppTheme.chocolate.withOpacity(0.35),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
