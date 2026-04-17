import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/user_session.dart';
import '../../../services/api_service.dart';

class MyCustomOrdersScreen extends StatefulWidget {
  const MyCustomOrdersScreen({super.key});

  @override
  State<MyCustomOrdersScreen> createState() => _MyCustomOrdersScreenState();
}

class _MyCustomOrdersScreenState extends State<MyCustomOrdersScreen> {
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
    final orders = await ApiService.getCustomOrdersByUser(userId);
    // Sort newest first
    orders.sort((a, b) {
      final da = DateTime.tryParse(a['dateOrdered']?.toString() ?? '') ??
          DateTime(2000);
      final db = DateTime.tryParse(b['dateOrdered']?.toString() ?? '') ??
          DateTime(2000);
      return db.compareTo(da);
    });
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'awaiting quote':
        return const Color(0xFF795548);
      case 'quoted':
        return const Color(0xFF0288D1);
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
      case 'awaiting quote':
        return Icons.hourglass_empty_rounded;
      case 'quoted':
        return Icons.price_check_rounded;
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
      case 'awaiting quote':
        return '⏳';
      case 'quoted':
        return '💬';
      case 'pending':
        return '🕐';
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

  String _statusDescription(String? status) {
    switch (status?.toLowerCase()) {
      case 'awaiting quote':
        return 'Our team is reviewing your order and will set a price soon.';
      case 'quoted':
        return 'We have priced your order! Please wait while we process your payment.';
      case 'pending':
        return 'Your order has been confirmed and is waiting to be prepared.';
      case 'preparing':
        return 'The bakers are crafting your custom order!';
      case 'ready for pickup':
        return 'Your order is packed and ready for delivery!';
      case 'delivered':
        return 'Order delivered! Enjoy your sweet treats! 🎉';
      case 'rejected':
        return 'Unfortunately this order was rejected. Please contact us for more details.';
      default:
        return '';
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
                      'My Custom Orders ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track your custom cake & cupcake orders',
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
                            const Text('🎂', style: TextStyle(fontSize: 60)),
                            const SizedBox(height: 16),
                            Text(
                              'No custom orders yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.chocolate.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your custom cake & cupcake orders\nwill appear here',
                              textAlign: TextAlign.center,
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
                            final orderType =
                                order['orderType']?.toString() ?? 'Custom';
                            final isCake = orderType == 'Cake';
                            final quotedPrice = order['quotedPrice'];
                            final hasPrice = quotedPrice != null &&
                                double.tryParse(quotedPrice.toString()) !=
                                    null &&
                                double.parse(quotedPrice.toString()) > 0;
                            final paymentStatus =
                                order['paymentStatus']?.toString() ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
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
                                  // ── Order Header ────────────────────
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
                                              Row(
                                                children: [
                                                  Text(
                                                    isCake ? '🎂' : '🧁',
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Custom $orderType #${order['customOrderId'] ?? '—'}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14,
                                                      color: AppTheme.darkChoco,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                _formatDate(order['dateOrdered']
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

                                  // ── Order Details ───────────────────
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Status description
                                        if (_statusDescription(status)
                                            .isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.07),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.info_outline,
                                                    size: 14, color: color),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _statusDescription(status),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: color,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],

                                        // Order details grid
                                        _DetailRow('Flavor',
                                            order['flavor']?.toString() ?? '—'),
                                        _DetailRow('Size',
                                            order['size']?.toString() ?? '—'),
                                        if (order['colorTheme'] != null &&
                                            order['colorTheme'].toString() !=
                                                'N/A' &&
                                            order['colorTheme']
                                                .toString()
                                                .isNotEmpty)
                                          _DetailRow('Color / Theme',
                                              order['colorTheme'].toString()),
                                        if (order['messageOnCake'] != null &&
                                            order['messageOnCake']
                                                .toString()
                                                .isNotEmpty)
                                          _DetailRow(
                                              'Message on Cake',
                                              order['messageOnCake']
                                                  .toString()),
                                        if (order['numberOfLayers'] != null &&
                                            isCake)
                                          _DetailRow('Layers',
                                              '${order['numberOfLayers']} layer${order['numberOfLayers'] == 1 ? '' : 's'}'),

                                        // Delivery info
                                        if (order['deliveryDate'] != null) ...[
                                          const SizedBox(height: 8),
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
                                                            .calendar_today_outlined,
                                                        size: 13,
                                                        color: AppTheme
                                                            .chocolate
                                                            .withOpacity(0.5)),
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
                                                if (order['deliveryAddress'] !=
                                                        null &&
                                                    order['deliveryAddress']
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .location_on_outlined,
                                                          size: 13,
                                                          color: AppTheme
                                                              .chocolate
                                                              .withOpacity(
                                                                  0.5)),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          order['deliveryAddress']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: AppTheme
                                                                .chocolate
                                                                .withOpacity(
                                                                    0.6),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],

                                        // Quoted price section
                                        if (hasPrice) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppTheme.chocolate
                                                      .withOpacity(0.08),
                                                  AppTheme.caramel
                                                      .withOpacity(0.05),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.caramel
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Quoted Price',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme
                                                            .chocolate
                                                            .withOpacity(0.55),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '₱${_formatPrice(quotedPrice)}',
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: AppTheme.caramel,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Payment status badge
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        paymentStatus == 'Paid'
                                                            ? const Color(
                                                                0xFF4CAF50)
                                                            : const Color(
                                                                0xFFE8A838),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    paymentStatus == 'Paid'
                                                        ? '✅ Paid'
                                                        : '⏳ Unpaid',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (paymentStatus != 'Paid' &&
                                              status != 'Rejected' &&
                                              status != 'Awaiting Quote') ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8A838)
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFFE8A838)
                                                            .withOpacity(0.3)),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.payment_outlined,
                                                      size: 14,
                                                      color: Color(0xFFE8A838)),
                                                  SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Please pay at our store or contact us to confirm payment.',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFFE8A838),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.chocolate.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.darkChoco,
                fontWeight: FontWeight.w600,
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
    if (price == null) return '0.00';
    final d = double.tryParse(price.toString()) ?? 0.0;
    return d.toStringAsFixed(2);
  }
}
