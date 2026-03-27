import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'order_status_screen.dart';
import 'notifications_screen.dart';

// ── Product Model ─────────────────────────────────────────────────────────────
class Product {
  final String id;
  final String name;
  final String category;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
  });
}

// ── Cart Item ─────────────────────────────────────────────────────────────────
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

//Types of Products
final List<Product> _products = [];

const List<String> _categories = [
  'All',
  'Cakes',
  'Bread',
  'Cookies',
  'Cupcakes'
];

// ── Cart State ────────────────────────────────────────────────────────────────
class _CartState extends ChangeNotifier {
  static final _CartState _instance = _CartState._internal();
  factory _CartState() => _instance;
  _CartState._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get totalCount => _items.fold(0, (s, i) => s + i.quantity);
  double get totalPrice => _items.fold(0.0, (s, i) => s + i.total);
  bool inCart(String id) => _items.any((i) => i.product.id == id);

  void add(Product p) {
    final idx = _items.indexWhere((i) => i.product.id == p.id);
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(product: p));
    }
    notifyListeners();
  }

  void increase(String id) {
    final idx = _items.indexWhere((i) => i.product.id == id);
    if (idx >= 0) {
      _items[idx].quantity++;
      notifyListeners();
    }
  }

  void decrease(String id) {
    final idx = _items.indexWhere((i) => i.product.id == id);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

final _cart = _CartState();

// ── Snackbar Helper ───────────────────────────────────────────────────────────
void _showSnack(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 2),
  ));
}

// ── Dashboard Screen ──────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _navIndex = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ✅ Stateful notif count — starts at 2 (welcome notifications), cleared when user reads
  int _notifCount = 2;

  // ✅ Called when user opens NotificationsScreen — clears all red dots
  void _clearNotifications() {
    if (_notifCount > 0) {
      setState(() => _notifCount = 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    _cart.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _cart.removeListener(_rebuild);
    _fadeCtrl.dispose();
    super.dispose();
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
            _HomeTab(onCartTap: () => setState(() => _navIndex = 2)),
            const _ExploreTab(),
            const _CartTab(),
            _ProfileTab(
              onLogout: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              // ✅ Pass the clear callback and current count down to ProfileTab
              notifCount: _notifCount,
              onNotifRead: _clearNotifications,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        cartCount: _cart.totalCount,
        notifCount: _notifCount,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final VoidCallback onCartTap;
  const _HomeTab({required this.onCartTap});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _selectedCategory = 'All';

  List<Product> get _filtered => _selectedCategory == 'All'
      ? _products
      : _products.where((p) => p.category == _selectedCategory).toList();

  @override
  void initState() {
    super.initState();
    _cart.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _cart.removeListener(_rebuild);
    super.dispose();
  }

  void _showProductSheet(Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(product.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.chocolate.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  )),
            ),
            const SizedBox(height: 8),
            Text(product.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkChoco,
                )),
            const SizedBox(height: 4),
            Text('₱${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.chocolate,
                )),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _cart.add(product);
                      Navigator.pop(context);
                      _showSnack(context, '${product.name} added to cart!',
                          AppTheme.chocolate);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.chocolate,
                      side: const BorderSide(color: AppTheme.chocolate),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add to Cart',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _cart.add(product);
                      Navigator.pop(context);
                      _showSnack(context, '${product.name} ordered!',
                          const Color(0xFF4CAF7D));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.chocolate,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('Order Now',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.chocolateGradient,
              borderRadius: const BorderRadius.only(
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('🧁', style: TextStyle(fontSize: 22)),
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
                                  fontSize: 15,
                                )),
                            Text('✦ Online Bakeshop ✦',
                                style: TextStyle(
                                  color: AppTheme.gold.withOpacity(0.85),
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                )),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: widget.onCartTap,
                      child: Stack(
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
                          if (_cart.totalCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: AppTheme.gold,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${_cart.totalCount}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      )),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Good day!',
                    style: TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Order your favorites\nfresh from the oven!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    )),
              ],
            ),
          ),
        ),

        // ── Category Filter ────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.chocolate : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.chocolate.withOpacity(0.08),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(cat,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.chocolate.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Products Grid — TEMPORARILY EMPTY ─────────────────
        SliverToBoxAdapter(
          child: _filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🍰',
                          style: TextStyle(
                            fontSize: 56,
                            color: AppTheme.chocolate.withOpacity(0.2),
                          )),
                      const SizedBox(height: 16),
                      Text(
                        'Products coming soon!',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.chocolate.withOpacity(0.45),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Check back later for fresh baked treats.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.chocolate.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Explore Tab ───────────────────────────────────────────────────────────────
class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 22,
              right: 22,
              bottom: 16,
            ),
            child: const Text('Explore Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkChoco,
                )),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Cart Tab ──────────────────────────────────────────────────────────────────
class _CartTab extends StatefulWidget {
  const _CartTab();

  @override
  State<_CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<_CartTab> {
  @override
  void initState() {
    super.initState();
    _cart.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _cart.removeListener(_rebuild);
    super.dispose();
  }

  void _placeOrder() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Order',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.darkChoco,
            )),
        content: Text(
          'Total: ₱${_cart.totalPrice.toStringAsFixed(0)}\n\nProceed with your order?',
          style: TextStyle(color: AppTheme.chocolate.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.chocolate)),
          ),
          ElevatedButton(
            onPressed: () {
              _cart.clear();
              Navigator.pop(context);
              _showSnack(context, 'Order placed successfully!',
                  const Color(0xFF4CAF7D));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.chocolate,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Place Order',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('My Cart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkChoco,
                )),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64, color: AppTheme.chocolate.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.chocolate.withOpacity(0.5),
                      )),
                  const SizedBox(height: 8),
                  Text('Add some sweet treats to get started!',
                      style: TextStyle(
                        color: AppTheme.chocolate.withOpacity(0.35),
                        fontSize: 13,
                      )),
                ],
              ),
            ),
          )
        else ...[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.chocolate.withOpacity(0.06),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.darkChoco,
                                )),
                            const SizedBox(height: 4),
                            Text(
                                '₱${item.product.price.toStringAsFixed(0)} each',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.chocolate.withOpacity(0.5),
                                )),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _cart.decrease(item.product.id),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.cream,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.remove_rounded,
                                  size: 16, color: AppTheme.chocolate),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppTheme.darkChoco,
                                )),
                          ),
                          GestureDetector(
                            onTap: () => _cart.increase(item.product.id),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.chocolate,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text('₱${item.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppTheme.chocolate,
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_cart.totalCount} item${_cart.totalCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppTheme.chocolate.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Total: ₱${_cart.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.darkChoco,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.chocolate,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Place Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final VoidCallback onLogout;
  final int notifCount; // ✅ NEW
  final VoidCallback onNotifRead; // ✅ NEW

  const _ProfileTab({
    required this.onLogout,
    required this.notifCount,
    required this.onNotifRead,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = AuthService.currentUser?['fullName'] ?? 'Guest';
    final email = AuthService.currentUser?['email'] ?? 'No email';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'G';

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
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                        color: AppTheme.gold.withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  fullName,
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
                      color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(label: 'Orders', value: '0'),
                    const SizedBox(width: 12),
                    _StatChip(label: 'Points', value: '0'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'My Order Status',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderStatusScreen()),
                  ),
                ),
                _ProfileTile(
                  icon: Icons.location_on_outlined,
                  label: 'Delivery Addresses',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Icon(Icons.location_on_outlined,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text('No Delivery Addresses',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            const Text('You have no saved addresses yet.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // ✅ Notifications tile with conditional red dot badge
                Container(
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
                    onTap: () async {
                      // ✅ Mark as read FIRST, then open screen
                      onNotifRead();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      );
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppTheme.darkChoco, size: 20),
                    ),
                    title: const Text('Notifications',
                        style: TextStyle(
                          color: AppTheme.darkChoco,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ Red dot — only shows when notifCount > 0
                        if (notifCount > 0)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        if (notifCount > 0) const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.chocolate.withOpacity(0.3)),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(height: 8),
                _ProfileTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  onTap: onLogout,
                  isDestructive: true,
                ),
                const SizedBox(height: 30),
                Text(
                  'Sweet Cengsations v2026 ✦',
                  style: TextStyle(
                    color: AppTheme.chocolate.withOpacity(0.3),
                    fontSize: 12,
                    letterSpacing: 1,
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

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              )),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
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
        title: Text(label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppTheme.chocolate.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final int notifCount; // NEW
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.cartCount,
    required this.notifCount, // NEW
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
              onTap: onTap),
          _NavItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore_rounded,
              label: 'Explore',
              index: 1,
              current: currentIndex,
              onTap: onTap),
          _NavItemCart(
              cartCount: cartCount,
              index: 2,
              current: currentIndex,
              onTap: onTap),
          // ✅ NEW: Profile nav item with red dot badge
          _NavItemProfile(
              notifCount: notifCount,
              index: 3,
              current: currentIndex,
              onTap: onTap),
        ],
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

// Nav Item Cart (with badge)
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
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
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppTheme.gold,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$cartCount',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
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
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

// Nav Item Profile (with red dot badge)
class _NavItemProfile extends StatelessWidget {
  final int notifCount;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItemProfile({
    required this.notifCount,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isActive
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  color: isActive
                      ? AppTheme.chocolate
                      : AppTheme.chocolate.withOpacity(0.35),
                  size: 26,
                ),
                // ✅ Red dot — shows when there are unread notifications
                if (notifCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text('Profile',
                style: TextStyle(
                  fontSize: 10,
                  color: isActive
                      ? AppTheme.chocolate
                      : AppTheme.chocolate.withOpacity(0.35),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}
