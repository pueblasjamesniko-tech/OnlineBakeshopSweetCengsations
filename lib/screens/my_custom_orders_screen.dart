import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../models/user_session.dart';
import '../../../services/api_service.dart';
import 'place_custom_order_screen.dart';

// This screen shows all the custom cake/cupcake orders the user made.
// Like a "My Orders" page in a bakery app!
class MyCustomOrdersScreen extends StatefulWidget {
  const MyCustomOrdersScreen({super.key});

  @override
  State<MyCustomOrdersScreen> createState() => _MyCustomOrdersScreenState();
}

class _MyCustomOrdersScreenState extends State<MyCustomOrdersScreen> {
  bool _isLoading = true;
  // A list (like a bag) that holds all the orders we fetched
  List<Map<String, dynamic>> _orders = [];

  // This runs automatically when the screen opens — like pressing "start"
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // This function asks the server for the user's orders, then saves them
  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final userId =
        int.tryParse(UserSession.instance.currentUser?.id ?? '0') ?? 0;
    final orders = await ApiService.getCustomOrdersByUser(userId);
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

  // This checks if the user is allowed to cancel an order.
  // Like checking if it's too late to cancel a pizza delivery!
  bool _canCancel(Map<String, dynamic> order) {
    final status = order['orderStatus']?.toString() ?? '';
    final paymentStatus = order['paymentStatus']?.toString() ?? '';
    final deliveryDateRaw = order['deliveryDate']?.toString() ?? '';

    // Can't cancel if the order is already done, being made, or paid for
    if (status == 'Cancelled' ||
        status == 'Rejected' ||
        status == 'Delivered' ||
        status == 'Preparing' ||
        status == 'Ready for Pickup') {
      return false;
    }
    if (paymentStatus == 'Paid' || paymentStatus == 'Receipt Submitted') {
      return false;
    }
    if (deliveryDateRaw.isEmpty) return true;

    // Can't cancel if today is already the delivery day or past it
    final deliveryDate = DateTime.tryParse(deliveryDateRaw);
    if (deliveryDate != null) {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final deliveryOnly =
          DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);
      if (todayOnly.isAfter(deliveryOnly) || todayOnly == deliveryOnly)
        return false;
    }
    return true;
  }

  // This pops up a "Are you sure?" message, then cancels the order if the user says yes
  Future<void> _cancelCustomOrder(int customOrderId) async {
    // Show a confirmation dialog — like asking "Do you really want to delete this?"
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Custom Order?',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppTheme.darkChoco)),
        content: const Text(
          'Are you sure you want to cancel this custom order? This action cannot be undone.',
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

    if (confirmed != true) return;

    // Tell the server to cancel this order
    final result = await ApiService.cancelCustomOrder(customOrderId);
    if (!mounted) return;

    // Show a message at the bottom of the screen telling if it worked or not
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        result['success'] == true
            ? '🚫 Custom order cancelled successfully.'
            : result['message'] ?? 'Failed to cancel order.',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor:
          result['success'] == true ? Colors.orange.shade700 : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));

    if (result['success'] == true) _loadOrders();
  }

  // Returns a color based on the order status — like a traffic light!
  // Green = good, Red = problem, Yellow = waiting
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'awaiting approval':
        return const Color(0xFF795548);
      case 'approved':
        return const Color(0xFF2E7D32);
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

  // Returns a small icon that matches what's happening with the order
  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'awaiting approval':
        return Icons.hourglass_empty_rounded;
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      case 'preparing':
        return Icons.soup_kitchen_outlined;
      case 'ready for pickup':
        return Icons.inventory_2_outlined;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // Returns a fun emoji for the order status — like stickers!
  String _statusEmoji(String? status) {
    switch (status?.toLowerCase()) {
      case 'awaiting approval':
        return '⏳';
      case 'approved':
        return '✅';
      case 'pending':
        return '🕐';
      case 'preparing':
        return '👨‍🍳';
      case 'ready for pickup':
        return '📦';
      case 'delivered':
        return '🎉';
      case 'rejected':
        return '❌';
      case 'cancelled':
        return '🚫';
      default:
        return '📋';
    }
  }

  // Returns a short message that explains the status in plain words
  String _statusDescription(String? status) {
    switch (status?.toLowerCase()) {
      case 'awaiting approval':
        return 'Your order is waiting for admin review and approval.';
      case 'approved':
        return 'Approved! Tap "Place Order Now" to confirm your payment.';
      case 'pending':
        return 'Your order is confirmed and waiting to be prepared.';
      case 'preparing':
        return 'The bakers are crafting your custom order!';
      case 'ready for pickup':
        return 'Your order is packed and ready!';
      case 'delivered':
        return 'Order delivered! Enjoy your sweet treats! 🎉';
      case 'rejected':
        return 'Unfortunately this order was rejected. Please contact us for more details.';
      case 'cancelled':
        return 'You have cancelled this custom order.';
      default:
        return '';
    }
  }

  // This lets the user pick a photo of their GCash receipt from their phone gallery
  // and sends it to the server as proof of payment
  Future<void> _uploadReceipt(int customOrderId) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final result = await ApiService.uploadCustomOrderReceipt(
      customOrderId: customOrderId,
      imageBytes: bytes,
      fileName: picked.name,
    );
    if (!mounted) return;
    // Show a message telling the user if the upload worked
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

  // This opens a big popup (bottom sheet) that shows all the details of one order
  // Like opening a receipt to see everything inside
  void _showOrderDetail(Map<String, dynamic> order) {
    final status = order['orderStatus']?.toString() ?? '';
    final color = _statusColor(status);
    final orderType = order['orderType']?.toString() ?? 'Custom';
    final isCake = orderType == 'Cake';
    final quotedPrice = order['quotedPrice'];
    final hasPrice = quotedPrice != null &&
        double.tryParse(quotedPrice.toString()) != null &&
        double.parse(quotedPrice.toString()) > 0;
    final paymentStatus = order['paymentStatus']?.toString() ?? '';
    final paymentMethod = order['paymentMethod']?.toString() ?? '';
    final customOrderId = order['customOrderId'] as int? ?? 0;
    final canCancel = _canCancel(order);

    // Show the detail popup from the bottom of the screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // The little gray bar at the top (like a handle to drag the popup)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header card showing the order type, ID, date, and status badge
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
                  Text(isCake ? '🎂' : '🧁',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom $orderType #$customOrderId',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppTheme.darkChoco),
                        ),
                        Text(
                          _formatDate(order['dateOrdered']?.toString() ?? ''),
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.chocolate.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                  // Colored status badge (e.g. "✅ Approved")
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(20)),
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
            // Scrollable section with all order details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show a helpful tip box explaining what the current status means
                    if (_statusDescription(status).isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusDescription(status),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Section showing cake customization details (flavor, size, etc.)
                    _DetailSection(
                      title: '✨ Customization',
                      child: Column(
                        children: [
                          _DetailRow(
                              'Flavor', order['flavor']?.toString() ?? '—'),
                          _DetailRow('Size', order['size']?.toString() ?? '—'),
                          if (order['colorTheme'] != null &&
                              order['colorTheme'].toString() != 'N/A' &&
                              order['colorTheme'].toString().isNotEmpty)
                            _DetailRow('Color / Theme',
                                order['colorTheme'].toString()),
                          if (order['messageOnCake'] != null &&
                              order['messageOnCake'].toString().isNotEmpty)
                            _DetailRow('Message on Cake',
                                order['messageOnCake'].toString()),
                          if (order['numberOfLayers'] != null && isCake)
                            _DetailRow('Layers',
                                '${order['numberOfLayers']} layer${order['numberOfLayers'] == 1 ? '' : 's'}'),
                          if (order['specialNotes'] != null &&
                              order['specialNotes'].toString().isNotEmpty &&
                              order['specialNotes'].toString() != 'None')
                            _DetailRow('Special Notes',
                                order['specialNotes'].toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Section showing when and where the order will be delivered
                    _DetailSection(
                      title: '📍 Delivery Info',
                      child: Column(
                        children: [
                          _DetailRow(
                            'Date',
                            order['deliveryDate'] != null
                                ? _formatDate(order['deliveryDate'].toString())
                                : '—',
                          ),
                          _DetailRow(
                            'Time',
                            order['deliveryTime']?.toString() ?? '—',
                          ),
                          _DetailRow(
                            'Address',
                            order['deliveryAddress']?.toString() ?? '—',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Show the price and payment status if a price has been set
                    if (hasPrice) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppTheme.chocolate.withOpacity(0.08),
                            AppTheme.caramel.withOpacity(0.05),
                          ]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.caramel.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quoted Price',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.chocolate
                                            .withOpacity(0.55),
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  '₱${_formatPrice(quotedPrice)}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.caramel),
                                ),
                              ],
                            ),
                            // Payment badge: Paid, Verifying, or Unpaid
                            if (paymentStatus.isNotEmpty &&
                                status != 'Awaiting Approval')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: paymentStatus == 'Paid'
                                      ? const Color(0xFF4CAF50)
                                      : paymentStatus == 'Receipt Submitted'
                                          ? Colors.blue.shade500
                                          : const Color(0xFFE8A838),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  paymentStatus == 'Paid'
                                      ? '✅ Paid'
                                      : paymentStatus == 'Receipt Submitted'
                                          ? '⏳ Verifying'
                                          : '⏳ Unpaid',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Show the GCash QR code and upload button if payment method is GCash and not yet paid
                    if (status != 'Awaiting Approval' &&
                        status != 'Approved' &&
                        status != 'Rejected' &&
                        status != 'Cancelled' &&
                        paymentMethod == 'GCash' &&
                        paymentStatus != 'Paid' &&
                        paymentStatus != 'Receipt Submitted') ...[
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
                              'Amount: ₱${_formatPrice(quotedPrice)}',
                              style: const TextStyle(
                                  color: AppTheme.caramel,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 12),
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
                            // Button to upload the GCash receipt photo
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _uploadReceipt(customOrderId);
                                },
                                icon: const Icon(Icons.upload_file_outlined,
                                    size: 18),
                                label: const Text('Upload GCash Receipt'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Show a "locked" message while the admin checks the receipt
                    if (paymentStatus == 'Receipt Submitted' &&
                        status != 'Awaiting Approval' &&
                        status != 'Approved') ...[
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
                    // Remind the user to prepare cash if they chose Cash on Delivery
                    if (status != 'Awaiting Approval' &&
                        status != 'Approved' &&
                        status != 'Rejected' &&
                        status != 'Cancelled' &&
                        paymentMethod == 'COD' &&
                        paymentStatus != 'Paid') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A838).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE8A838).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.payment_outlined,
                                size: 16, color: Color(0xFFE8A838)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Please prepare cash upon delivery or pickup.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFE8A838),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // "Place Order Now" button — only shows when admin has approved the order
                    if (status == 'Approved') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaceCustomOrderScreen(
                                  customOrderId: customOrderId,
                                  quotedPrice:
                                      double.parse(quotedPrice.toString()),
                                  orderType: orderType,
                                  prefillDeliveryDate:
                                      order['deliveryDate']?.toString() ?? '',
                                  prefillDeliveryTime:
                                      order['deliveryTime']?.toString() ?? '',
                                  prefillDeliveryAddress:
                                      order['deliveryAddress']?.toString() ??
                                          '',
                                ),
                              ),
                            );
                            if (result == true) _loadOrders();
                          },
                          icon:
                              const Text('🛍️', style: TextStyle(fontSize: 16)),
                          label: const Text('Place Order Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.chocolate,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // "Cancel Order" button — only shows if cancellation is still allowed
                    if (canCancel) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _cancelCustomOrder(customOrderId);
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
                  ],
                ),
              ),
            ),
          ],
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
          // The top header bar with the title and a refresh button
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
                // Back button — goes to the previous screen
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
                    Text('My Custom Orders ✨',
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
          // The main content area — shows loading spinner, empty message, or the orders list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.chocolate))
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎂', style: TextStyle(fontSize: 60)),
                            const SizedBox(height: 16),
                            Text('No custom orders yet',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        AppTheme.chocolate.withOpacity(0.5))),
                            const SizedBox(height: 8),
                            Text(
                                'Your custom cake & cupcake orders\nwill appear here',
                                textAlign: TextAlign.center,
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
                            final customOrderId =
                                order['customOrderId'] as int? ?? 0;

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
                                            _formatDate(order['dateOrdered']
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
                                    // Middle row: emoji icon, order name, flavor/size, price, payment badge
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppTheme.blush
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                isCake ? '🎂' : '🧁',
                                                style: const TextStyle(
                                                    fontSize: 24),
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
                                                  'Custom $orderType #$customOrderId',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                      color:
                                                          AppTheme.darkChoco),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${order['flavor'] ?? '—'} • ${order['size'] ?? '—'}',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.chocolate
                                                          .withOpacity(0.55)),
                                                ),
                                                if (hasPrice)
                                                  Text(
                                                    '₱${_formatPrice(quotedPrice)}',
                                                    style: const TextStyle(
                                                        color: AppTheme.caramel,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 13),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Small payment status badge on the right
                                          if (paymentStatus.isNotEmpty &&
                                              status != 'Awaiting Approval' &&
                                              status != 'Approved')
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: paymentStatus == 'Paid'
                                                    ? const Color(0xFF4CAF50)
                                                    : paymentStatus ==
                                                            'Receipt Submitted'
                                                        ? Colors.blue.shade500
                                                        : const Color(
                                                            0xFFE8A838),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                paymentStatus == 'Paid'
                                                    ? '✅ Paid'
                                                    : paymentStatus ==
                                                            'Receipt Submitted'
                                                        ? '⏳ Verify'
                                                        : '⏳ Unpaid',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Bottom hint text telling the user to tap the card
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

  // Turns a date string like "2024-12-25" into a nice readable "Dec 25, 2024"
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
    if (price == null) return '0.00';
    final d = double.tryParse(price.toString()) ?? 0.0;
    return d.toStringAsFixed(2);
  }
}

// A reusable box with a title and content inside — used for "Customization" and "Delivery Info" sections
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

// A single row that shows a label on the left and a value on the right
// Like: "Flavor    Chocolate"
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
