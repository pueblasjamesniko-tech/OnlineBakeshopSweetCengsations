import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

// This screen is the final checkout page for a custom order.
// The user picks how they want to pay, then confirms the order!
class PlaceCustomOrderScreen extends StatefulWidget {
  // These are the details passed in from the previous screen
  final int customOrderId; // The ID number of the custom order
  final double quotedPrice; // How much the order costs
  final String orderType; // "Cake" or "Cupcake"
  final String prefillDeliveryDate; // Pre-filled delivery date
  final String prefillDeliveryTime; // Pre-filled delivery time
  final String prefillDeliveryAddress; // Pre-filled delivery address

  const PlaceCustomOrderScreen({
    super.key,
    required this.customOrderId,
    required this.quotedPrice,
    required this.orderType,
    required this.prefillDeliveryDate,
    required this.prefillDeliveryTime,
    required this.prefillDeliveryAddress,
  });

  @override
  State<PlaceCustomOrderScreen> createState() => _PlaceCustomOrderScreenState();
}

// True while the order is being sent to the server — disables the button
// Which payment method the user picked — starts as Cash on Delivery
class _PlaceCustomOrderScreenState extends State<PlaceCustomOrderScreen> {
  bool _isSubmitting = false;
  String _paymentMethod = 'COD';

  // Holds the receipt image the user picked (as raw bytes)
  // The file name of the receipt image
  Uint8List? _receiptBytes;
  String? _receiptFileName;

  // Opens the phone gallery so the user can pick their GCash receipt photo.
  // Once a receipt is picked, it can't be changed (locked in).
  Future<void> _pickReceipt() async {
    if (_receiptBytes != null) return;
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _receiptBytes = bytes;
        _receiptFileName = picked.name;
      });
    }
  }

  // Shows a quick pop-up message at the bottom of the screen.
  // Red for errors, green for success.
  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // The main function that runs when the user taps "Confirm Order".
  // It validates, sends the order to the server, and uploads the receipt if needed.
  Future<void> _submitOrder() async {
    // If the user chose GCash but hasn't uploaded a receipt yet, stop and warn them
    if (_paymentMethod == 'GCash' && _receiptBytes == null) {
      _snack('Please upload your GCash receipt');
      return;
    }

    setState(() => _isSubmitting = true);

    // Send the order details to the server
    final result = await ApiService.placeCustomOrder(
      customOrderId: widget.customOrderId,
      paymentMethod: _paymentMethod,
      deliveryDate: widget.prefillDeliveryDate,
      deliveryTime: widget.prefillDeliveryTime,
      deliveryAddress: widget.prefillDeliveryAddress,
      fulfillmentType: 'Delivery',
      meetupPlace: null,
    );

    // If the order was placed successfully and payment is GCash, also upload the receipt
    if (result['success'] == true &&
        _paymentMethod == 'GCash' &&
        _receiptBytes != null) {
      await ApiService.uploadCustomOrderReceipt(
        customOrderId: widget.customOrderId,
        imageBytes: _receiptBytes!,
        fileName: _receiptFileName ?? 'receipt.jpg',
      );
    }

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (result['success'] == true) {
      _snack('Order placed successfully!', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } else {
      _snack(result['message'] ?? 'Failed to place order. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
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
                        const Text('Confirm & Pay',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkChoco)),
                      ],
                    ),
                  ),
                  // Order summary card showing the type, ID, and total price
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: AppTheme.chocolateGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(widget.orderType == 'Cake' ? '🎂' : '🧁',
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Custom ${widget.orderType}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text('Order #${widget.customOrderId}',
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                            Text('₱${widget.quotedPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scrollable body with delivery details, payment method, and confirm button
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Delivery details (read-only — can't be edited here)
                  _SectionLabel('📍 Delivery Details'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      children: [
                        _ReadOnlyRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: _formatDisplayDate(widget.prefillDeliveryDate),
                        ),
                        const Divider(height: 20, color: Color(0xFFEEE0D4)),
                        _ReadOnlyRow(
                          icon: Icons.access_time_outlined,
                          label: 'Time',
                          value: widget.prefillDeliveryTime.isNotEmpty
                              ? widget.prefillDeliveryTime
                              : '—',
                        ),
                        const Divider(height: 20, color: Color(0xFFEEE0D4)),
                        _ReadOnlyRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: widget.prefillDeliveryAddress.isNotEmpty
                              ? widget.prefillDeliveryAddress
                              : '—',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Section: Payment method — user picks COD or GCash
                  _SectionLabel('💳 Payment Method'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceChip(
                          label: '💵 Cash on Delivery',
                          selected: _paymentMethod == 'COD',
                          onTap: () => setState(() {
                            _paymentMethod = 'COD';
                            _receiptBytes = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChoiceChip(
                          label: '📱 GCash',
                          selected: _paymentMethod == 'GCash',
                          onTap: () => setState(() => _paymentMethod = 'GCash'),
                        ),
                      ),
                    ],
                  ),
                  // GCash payment section — only shows when GCash is selected
                  if (_paymentMethod == 'GCash') ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.chocolate.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Scan to Pay via GCash',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.darkChoco)),
                          const SizedBox(height: 4),
                          Text(
                              'Amount: ₱${widget.quotedPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppTheme.caramel,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/gcash_qr.jpg',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFEEE0D4)),
                          const SizedBox(height: 8),
                          const Text('Upload GCash Receipt',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.darkChoco)),
                          const SizedBox(height: 4),
                          Text(
                            'After paying, screenshot your GCash receipt and upload it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.55),
                                fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          // If a receipt was already uploaded, show a preview and lock it
                          if (_receiptBytes != null) ...[
                            // Preview of the uploaded receipt image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _receiptBytes!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: const Row(children: [
                                Icon(Icons.lock_rounded,
                                    size: 14, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Receipt attached. Cannot be changed.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ]),
                            ),
                          ] else
                            // No receipt yet — show a tap-to-upload box
                            GestureDetector(
                              onTap: _pickReceipt,
                              child: Container(
                                height: 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.cream,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          AppTheme.roseDust.withOpacity(0.4)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file_outlined,
                                        color:
                                            AppTheme.chocolate.withOpacity(0.4),
                                        size: 28),
                                    const SizedBox(height: 4),
                                    Text('Tap to upload receipt',
                                        style: TextStyle(
                                            color: AppTheme.chocolate
                                                .withOpacity(0.45),
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  // The big "Confirm Order" button at the bottom.
                  // Shows a spinner while submitting and is disabled to prevent double-tapping.
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.chocolate,
                        disabledBackgroundColor:
                            AppTheme.chocolate.withOpacity(0.5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Confirm Order',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Turns a raw date string like "2024-12-25" into a nice "Dec 25, 2024"
  String _formatDisplayDate(String raw) {
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
}

// A read-only info row with an icon, a small label, and a value below it.
// Used for showing delivery date, time, and address — the user can't edit these here.
class _ReadOnlyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadOnlyRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.caramel.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.chocolate.withOpacity(0.5))),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkChoco)),
            ],
          ),
        ),
      ],
    );
  }
}

// A bold section title used above each group of content (e.g. "📍 Delivery Details")
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

// A tappable button chip used for picking a payment method (COD or GCash).
// The selected chip turns chocolate brown; the unselected one stays white.
class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected; // Is this chip currently chosen?
  final VoidCallback onTap; // What happens when the user taps it

  const _ChoiceChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // AnimatedContainer smoothly animates the color change when selected/unselected
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.chocolate : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? AppTheme.chocolate
                  : AppTheme.roseDust.withOpacity(0.4)),
          // Selected chip gets a shadow to look "pressed in"
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
                  // White text when selected, dark text when not
                  color: selected ? Colors.white : AppTheme.darkChoco,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      ),
    );
  }
}
