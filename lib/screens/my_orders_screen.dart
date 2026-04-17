import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/user_session.dart';
import '../../../services/api_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final userId =
        int.tryParse(UserSession.instance.currentUser?.id ?? '0') ?? 0;
    final orders = await ApiService.getOrdersByUser(userId);
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return const Color(0xFFE8A838);
      case 'preparing':
        return const Color(0xFF1565C0);
      case 'ready for pickup':
        return const Color(0xFF6A1B9A);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'preparing':
        return Icons.soup_kitchen_outlined;
      case 'ready for pickup':
        return Icons.inventory_2_outlined;
      case 'delivered':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _statusEmoji(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return '⏳';
      case 'preparing':
        return '👨‍🍳';
      case 'ready for pickup':
        return '📦';
      case 'delivered':
        return '✅';
      case 'rejected':
        return '❌';
      default:
        return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.chocolateGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Orders 🛒',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track all your regular orders',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadOrders,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.chocolate),
                  )
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🛒', style: TextStyle(fontSize: 60)),
                            const SizedBox(height: 16),
                            Text(
                              'No orders yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.chocolate.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your regular orders will appear here',
                              style: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.35),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        color: AppTheme.chocolate,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (_, i) {
                            final order = _orders[i];
                            final status =
                                order['orderStatus']?.toString() ?? '';
                            final color = _statusColor(status);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.chocolate.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Order Header ──────────────────────
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.08),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              _statusIcon(status),
                                              color: color,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Order #${order['orderId'] ?? '—'}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: AppTheme.darkChoco,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(order['orderDate']
                                                        ?.toString() ??
                                                    ''),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.chocolate
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${_statusEmoji(status)} $status',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── Order Details ─────────────────────
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Product info
                                        Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: SizedBox(
                                                width: 52,
                                                height: 52,
                                                child: (order['imageUrl'] !=
                                                            null &&
                                                        order['imageUrl']
                                                            .toString()
                                                            .isNotEmpty)
                                                    ? Image.network(
                                                        '${ApiService.baseUrl}${order['imageUrl']}',
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, __, ___) =>
                                                                Container(
                                                          color: AppTheme.blush
                                                              .withOpacity(0.3),
                                                          child: const Center(
                                                            child: Text('🎂',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        22)),
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        color: AppTheme.blush
                                                            .withOpacity(0.3),
                                                        child: const Center(
                                                          child: Text('🎂',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      22)),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    order['productName']
                                                            ?.toString() ??
                                                        'Product #${order['productId']}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                      color: AppTheme.darkChoco,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'Qty: ${order['quantity'] ?? 1}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.chocolate
                                                          .withOpacity(0.55),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '₱${_formatPrice(order['totalPrice'])}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: AppTheme.caramel,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Delivery info
                                        if (order['deliveryAddress'] != null &&
                                            order['deliveryAddress']
                                                .toString()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.cream,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        size: 13,
                                                        color: AppTheme
                                                            .chocolate
                                                            .withOpacity(0.5)),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        order['deliveryAddress']
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .chocolate
                                                              .withOpacity(0.6),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (order['deliveryDate'] !=
                                                        null &&
                                                    order['deliveryDate']
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .calendar_today_outlined,
                                                          size: 13,
                                                          color: AppTheme
                                                              .chocolate
                                                              .withOpacity(
                                                                  0.5)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '${_formatDate(order['deliveryDate'].toString())}${order['deliveryTime'] != null ? ' at ${order['deliveryTime']}' : ''}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .chocolate
                                                              .withOpacity(0.6),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],

                                        // Status timeline hint
                                        if (status == 'Rejected') ...[
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD32F2F)
                                                  .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: const Color(0xFFD32F2F)
                                                      .withOpacity(0.2)),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.info_outline,
                                                    size: 14,
                                                    color: Color(0xFFD32F2F)),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'This order has been rejected. Please contact us for more info.',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFFD32F2F),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final d = double.tryParse(price.toString()) ?? 0.0;
    return d.toStringAsFixed(2);
  }
}
