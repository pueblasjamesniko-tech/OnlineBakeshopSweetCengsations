import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../models/user_session.dart';
import '../../../services/api_service.dart';
import 'my_orders_screen.dart';

// This screen shows all the regular (non-custom) orders the user has placed.
// Like a "Order History" page in a food delivery app!
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

// True means we are still fetching orders — show a spinner
// A list that holds all the orders we got from the server
class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  // Runs automatically when the screen opens — kicks off the data loading
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // Asks the server for this user's orders, then saves and sorts them
  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final userId =
        int.tryParse(UserSession.instance.currentUser?.id ?? '0') ?? 0;
    final orders = await ApiService.getOrdersByUser(userId);
    orders.sort((a, b) {
      final da =
          DateTime.tryParse(a['orderDate']?.toString() ?? '') ?? DateTime(2000);
      final db =
          DateTime.tryParse(b['orderDate']?.toString() ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });
    // Save the orders and hide the loading spinner
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  // Checks if the user is still allowed to cancel this order.
  // Like checking if it's too late to cancel a food delivery!
  bool _canCancel(Map<String, dynamic> order) {
    final status = order['orderStatus']?.toString() ?? '';
    final paymentStatus = order['paymentStatus']?.toString() ?? '';
    final deliveryDateRaw = order['deliveryDate']?.toString() ?? '';

    // Can't cancel if the order is already too far along or done
    if (status == 'Cancelled' ||
        status == 'Rejected' ||
        status == 'Delivered' ||
        status == 'Preparing' ||
        status == 'Ready for Pickup') {
      return false;
    }
    // Can't cancel if money has already been paid or receipt was sent
    if (paymentStatus == 'Paid' || paymentStatus == 'Receipt Submitted') {
      return false;
    }
    // Can't cancel if today is already the delivery day or past it
    if (deliveryDateRaw.isNotEmpty) {
      final deliveryDate = DateTime.tryParse(deliveryDateRaw);
      if (deliveryDate != null) {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final deliveryOnly =
            DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);
        if (todayOnly.isAfter(deliveryOnly) || todayOnly == deliveryOnly)
          return false;
      }
    }
    return true;
  }

  // Shows a "Are you sure?" popup, then cancels the order if the user says yes
  Future<void> _cancelOrder(int orderId) async {
    // Ask the user to confirm before cancelling
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Order?',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppTheme.darkChoco)),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: TextStyle(color: AppTheme.chocolate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep It',
                style: TextStyle(color: AppTheme.chocolate)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return; // User changed their mind, do nothing

    // Tell the server to cancel this order
    final result = await ApiService.cancelOrder(orderId);
    if (!mounted) return;

    // Show a pop-up message at the bottom saying if it worked or not
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        result['success'] == true
            ? '🚫 Order cancelled successfully.'
            : result['message'] ?? 'Failed to cancel order.',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor:
          result['success'] == true ? Colors.orange.shade700 : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));

    // Reload the list so the cancelled order shows the updated status
    if (result['success'] == true) _loadOrders();
  }

  // Returns a color that matches the order status — like a traffic light!
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
      case 'cancelled':
        return const Color(0xFFFF6F00);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  // Returns an icon that matches the order status
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
      case 'cancelled':
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // Returns a fun emoji sticker for the order status
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
      case 'cancelled':
        return '🚫';
      default:
        return '📋';
    }
  }

  // Lets the user pick a photo of their GCash receipt and sends it to the server
  Future<void> _uploadReceipt(int orderId) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final result = await ApiService.uploadOrderReceipt(
      orderId: orderId,
      imageBytes: bytes,
      fileName: picked.name,
    );
    if (!mounted) return;
    // Show a message telling the user if the upload worked or not
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true
          ? '✅ Receipt uploaded! Waiting for admin confirmation.'
          : result['message'] ?? 'Upload failed'),
      backgroundColor:
          result['success'] == true ? Colors.green.shade600 : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
    if (result['success'] == true) _loadOrders();
  }

  // Opens a big popup from the bottom showing all details of one order
  void _showOrderDetail(Map<String, dynamic> order) {
    final status = order['orderStatus']?.toString() ?? '';
    final color = _statusColor(status);
    final paymentMethod = order['paymentMethod']?.toString() ?? 'COD';
    final paymentStatus = order['paymentStatus']?.toString() ?? '';
    final fulfillmentType = order['fulfillmentType']?.toString() ?? 'Delivery';
    final orderId = order['orderId'] as int? ?? 0;
    final canCancel = _canCancel(order);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder lets the popup update itself without rebuilding the whole screen
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header showing order number, date, and status badge
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Icon(_statusIcon(status),
                              color: color, size: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order['orderId'] ?? '—'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.darkChoco),
                          ),
                          Text(
                            _formatDate(order['orderDate']?.toString() ?? ''),
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.chocolate.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${_statusEmoji(status)} $status',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content below the header
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product section — shows the item photo, name, quantity, and price
                      _DetailSection(
                        title: '🛍️ Product',
                        child: Row(
                          children: [
                            // Product image — loads from the internet, shows 🎂 if it fails
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: (order['imageUrl'] != null &&
                                        order['imageUrl'].toString().isNotEmpty)
                                    ? Image.network(
                                        '${ApiService.baseUrl}${order['imageUrl']}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color:
                                              AppTheme.blush.withOpacity(0.3),
                                          child: const Center(
                                              child: Text('🎂',
                                                  style:
                                                      TextStyle(fontSize: 22))),
                                        ),
                                      )
                                    : Container(
                                        color: AppTheme.blush.withOpacity(0.3),
                                        child: const Center(
                                            child: Text('🎂',
                                                style:
                                                    TextStyle(fontSize: 22))),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['productName']?.toString() ??
                                        'Product #${order['productId']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppTheme.darkChoco),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${order['quantity'] ?? 1}  •  ₱${_formatPrice(order['totalPrice'])}',
                                    style: const TextStyle(
                                        color: AppTheme.caramel,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Delivery section — shows date, time, address, and special notes
                      _DetailSection(
                        title: '📍 Delivery Info',
                        child: Column(
                          children: [
                            _DetailRow('Type', fulfillmentType),
                            if (order['deliveryDate'] != null)
                              _DetailRow(
                                'Schedule',
                                '${_formatDate(order['deliveryDate'].toString())}${order['deliveryTime'] != null ? ' at ${order['deliveryTime']}' : ''}',
                              ),
                            if (order['deliveryAddress'] != null &&
                                order['deliveryAddress'].toString().isNotEmpty)
                              _DetailRow('Address / Meetup',
                                  order['deliveryAddress'].toString()),
                            if (order['specialNotes'] != null &&
                                order['specialNotes'].toString().isNotEmpty)
                              _DetailRow('Special Notes',
                                  order['specialNotes'].toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Payment section — shows how the user is paying and if they've paid
                      _DetailSection(
                        title: '💳 Payment',
                        child: Column(
                          children: [
                            _DetailRow(
                              'Method',
                              paymentMethod == 'GCash'
                                  ? '📱 GCash'
                                  : '💵 Cash on Delivery',
                            ),
                            _DetailRow('Status', paymentStatus),
                          ],
                        ),
                      ),
                      // Show GCash QR code and upload button if not yet paid via GCash
                      if (paymentMethod == 'GCash' &&
                          paymentStatus != 'Paid' &&
                          paymentStatus != 'Receipt Submitted' &&
                          status != 'Rejected' &&
                          status != 'Cancelled') ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100),
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.chocolate.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text('💳 Pay via GCash',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppTheme.darkChoco)),
                              const SizedBox(height: 4),
                              Text(
                                'Amount: ₱${_formatPrice(order['totalPrice'])}',
                                style: const TextStyle(
                                    color: AppTheme.caramel,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              // QR code image the user scans to send the payment
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/gcash_qr.jpg',
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Color(0xFFEEE0D4)),
                              const SizedBox(height: 8),
                              // Button to upload the GCash receipt photo as proof of payment
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await _uploadReceipt(orderId);
                                  },
                                  icon: const Icon(Icons.upload_file_outlined,
                                      size: 18),
                                  label: const Text('Upload GCash Receipt'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Show a "locked" notice while the admin is checking the receipt
                      if (paymentStatus == 'Receipt Submitted') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 16, color: Colors.blue.shade600),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Receipt locked. Admin is verifying your payment.',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Cancel button — only shows if the order can still be cancelled
                      if (canCancel) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _cancelOrder(orderId);
                            },
                            icon: const Icon(Icons.cancel_outlined,
                                size: 18, color: Colors.redAccent),
                            label: const Text('Cancel Order',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                      // Show a red notice if the order was rejected by the admin
                      if (status == 'Rejected') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color(0xFFD32F2F).withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Color(0xFFD32F2F)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This order has been rejected. Please contact us for more info.',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFFD32F2F)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Show an orange notice if the user cancelled the order
                      if (status == 'Cancelled') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F00).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color(0xFFFF6F00).withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.block_rounded,
                                  size: 16, color: Color(0xFFFF6F00)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You have cancelled this order.',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFFFF6F00)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // Top header bar with title and refresh button
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
                // Back button — goes back to the previous screen
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Orders 🛒',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Tap an order to see details',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
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
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Main body — shows spinner, empty message, or the orders list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.chocolate))
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🛒', style: TextStyle(fontSize: 60)),
                            const SizedBox(height: 16),
                            Text('No orders yet',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        AppTheme.chocolate.withOpacity(0.5))),
                            const SizedBox(height: 8),
                            Text('Your regular orders will appear here',
                                style: TextStyle(
                                    color: AppTheme.chocolate.withOpacity(0.35),
                                    fontSize: 13)),
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
                            final paymentMethod =
                                order['paymentMethod']?.toString() ?? 'COD';
                            final paymentStatus =
                                order['paymentStatus']?.toString() ?? '';

                            // Each order is a tappable card that opens the detail popup
                            return GestureDetector(
                              onTap: () => _showOrderDetail(order),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppTheme.chocolate
                                            .withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.08),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(18)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(_statusIcon(status),
                                              color: color, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_statusEmoji(status)} $status',
                                            style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatDate(order['orderDate']
                                                    ?.toString() ??
                                                ''),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.chocolate
                                                    .withOpacity(0.5)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Middle row: product image, name, price, payment badge
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          // Product image — loads from internet or shows 🎂 fallback
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
                                                                        22))),
                                                      ),
                                                    )
                                                  : Container(
                                                      color: AppTheme.blush
                                                          .withOpacity(0.3),
                                                      child: const Center(
                                                          child: Text('🎂',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      22))),
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
                                                      color:
                                                          AppTheme.darkChoco),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  'Qty: ${order['quantity'] ?? 1}  •  ₱${_formatPrice(order['totalPrice'])}',
                                                  style: const TextStyle(
                                                      color: AppTheme.caramel,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  paymentMethod == 'GCash'
                                                      ? '📱 GCash'
                                                      : '💵 Cash on Delivery',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.chocolate
                                                          .withOpacity(0.55)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: paymentStatus == 'Paid'
                                                  ? Colors.green.shade500
                                                  : paymentStatus ==
                                                          'Receipt Submitted'
                                                      ? Colors.blue.shade500
                                                      : Colors.orange.shade400,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              paymentStatus == 'Paid'
                                                  ? '✅ Paid'
                                                  : paymentStatus ==
                                                          'Receipt Submitted'
                                                      ? '⏳ Verifying'
                                                      : '⏳ ${paymentStatus}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Bottom hint telling the user to tap for details
                                    Container(
                                      padding: const EdgeInsets.only(
                                          bottom: 10, right: 14),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Tap to view details →',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.chocolate
                                                    .withOpacity(0.4),
                                                fontStyle: FontStyle.italic),
                                          ),
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
          ),
        ],
      ),
    );
  }

  // Turns a raw date string like "2024-12-25" into a nice "Dec 25, 2024"
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

  // Turns a price number into a clean "0.00" format
  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final d = double.tryParse(price.toString()) ?? 0.0;
    return d.toStringAsFixed(2);
  }
}

// A reusable box with a title and content — used for Product, Delivery, and Payment sections
class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkChoco)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// A single row with a label on the left and a value on the right
// Example: "Method    📱 GCash"
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.chocolate.withOpacity(0.55),
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkChoco,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
