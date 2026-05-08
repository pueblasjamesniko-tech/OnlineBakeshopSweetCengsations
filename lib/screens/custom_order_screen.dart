import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_theme.dart';
import '../../../models/cart_item.dart';
import '../../../models/user_session.dart';
import '../../../services/api_service.dart';

// Screen where the user builds their custom cake or cupcake order
class CustomOrderScreen extends StatefulWidget {
  final String orderType;
  final ValueChanged<CartItem> onSubmitted;

  const CustomOrderScreen({
    super.key,
    required this.orderType,
    required this.onSubmitted,
  });

  @override
  State<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends State<CustomOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  String? _selectedFlavor;
  String? _selectedSize;
  final _colorThemeCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  int _layers = 1;
  final _notesCtrl = TextEditingController();
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;
  final _addressCtrl = TextEditingController();

  // Holds the picked image as bytes so it works on both mobile and web
  Uint8List? _referenceImageBytes;
  String? _referenceImageFileName;
  String? _referenceImageMimeType;
  String? _referenceImageUrl; // path returned by server after upload

  // Auto-fills the delivery address when the screen opens
  @override
  void initState() {
    super.initState();
    final defaultAddress = UserSession.instance.selectedDeliveryAddress;
    if (defaultAddress.isNotEmpty) {
      _addressCtrl.text = defaultAddress;
    }
  }

  // List of available flavors to choose from
  List<String> get _flavors => [
        'Chocolate',
        'Vanilla',
        'Red Velvet',
        'Strawberry',
        'Caramel',
        'Lemon',
        'Matcha',
        'Ube',
      ];

  // Size options change depending on whether it's a cake or cupcakes
  List<String> get _sizes => widget.orderType == 'Cake'
      ? [
          '6 inch (6–8 pax)',
          '8 inch (10–12 pax)',
          '10 inch (15–20 pax)',
          '12 inch (25–30 pax)'
        ]
      : ['6 pieces', '12 pieces', '24 pieces', '36 pieces'];

  // Emoji shown in the header based on order type
  String get _emoji => widget.orderType == 'Cake' ? '🎂' : '🧁';

  // Shows a readable date or a placeholder if none is picked yet
  String get _formattedDate => _deliveryDate == null
      ? 'Select date'
      : '${_deliveryDate!.year}-${_deliveryDate!.month.toString().padLeft(2, '0')}-${_deliveryDate!.day.toString().padLeft(2, '0')}';

  // Shows a readable time or a placeholder if none is picked yet
  String get _formattedTime =>
      _deliveryTime == null ? 'Select time' : _deliveryTime!.format(context);

  // Opens the date picker so the user can choose a delivery date
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
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

  // Opens the time picker so the user can choose a delivery time
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

  // Opens the gallery so the user can pick a reference image
  Future<void> _pickReferenceImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _referenceImageBytes = bytes;
        _referenceImageFileName = picked.name;
        _referenceImageMimeType = picked.mimeType ?? 'image/jpeg';
      });
    }
  }

  // Uploads the reference image to the server and returns its URL
  Future<String?> _uploadReferenceImage() async {
    if (_referenceImageBytes == null) return null;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/Upload/UploadReferenceImage'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _referenceImageBytes!,
        filename: _referenceImageFileName ?? 'reference.jpg',
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final match = RegExp(r'"[Ii]mage[Uu]rl"\s*:\s*"([^"]+)"')
            .firstMatch(response.body);
        return match?.group(1);
      } else {
        debugPrint(
            'Upload reference image failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Upload reference image error: $e');
    }
    return null;
  }

  // Validates the form, uploads the image if any, then sends the order to the API
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFlavor == null) {
      _showSnack('Please select a flavor', isError: true);
      return;
    }
    if (_selectedSize == null) {
      _showSnack('Please select a size', isError: true);
      return;
    }
    if (_deliveryDate == null) {
      _showSnack('Please select a delivery date', isError: true);
      return;
    }
    if (_deliveryTime == null) {
      _showSnack('Please select a delivery time', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    // Upload reference image first if the user picked one
    if (_referenceImageBytes != null) {
      _referenceImageUrl = await _uploadReferenceImage();
    }

    final userId =
        int.tryParse(UserSession.instance.currentUser?.id ?? '0') ?? 0;

    final result = await ApiService.createCustomOrder(
      userId: userId,
      orderType: widget.orderType,
      flavor: _selectedFlavor!,
      size: _selectedSize!,
      colorTheme: _colorThemeCtrl.text.trim().isEmpty
          ? 'N/A'
          : _colorThemeCtrl.text.trim(),
      messageOnCake: _messageCtrl.text.trim(),
      numberOfLayers: widget.orderType == 'Cake' ? _layers : 1,
      specialNotes:
          _notesCtrl.text.trim().isEmpty ? 'None' : _notesCtrl.text.trim(),
      deliveryDate: _formattedDate,
      deliveryTime: _formattedTime,
      deliveryAddress: _addressCtrl.text.trim(),
      referenceImage: _referenceImageUrl ?? '',
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    // If successful, build a CartItem and pass it back to the parent
    if (result['success'] == true) {
      final cartItem = CartItem.custom(
        customLabel: 'Custom ${widget.orderType}',
        customEmoji: _emoji,
        customData: {
          'orderType': widget.orderType,
          'flavor': _selectedFlavor,
          'size': _selectedSize,
          'colorTheme': _colorThemeCtrl.text.trim().isEmpty
              ? 'N/A'
              : _colorThemeCtrl.text.trim(),
          'messageOnCake': _messageCtrl.text.trim(),
          'layers': _layers,
          'notes': _notesCtrl.text.trim(),
          'deliveryDate': _formattedDate,
          'deliveryTime': _formattedTime,
          'deliveryAddress': _addressCtrl.text.trim(),
          'referenceImage': _referenceImageUrl ?? '',
        },
      );
      widget.onSubmitted(cartItem);
    } else {
      _showSnack(
        result['message'] ?? 'Failed to submit. Please try again.',
        isError: true,
      );
    }
  }

  // Shows a small pop-up message at the bottom of the screen
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Cleans up all text controllers when the screen is closed
  @override
  void dispose() {
    _colorThemeCtrl.dispose();
    _messageCtrl.dispose();
    _notesCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: CustomScrollView(
        slivers: [
          // App bar with a gradient header showing the order type
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.chocolate,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppTheme.chocolateGradient),
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 28, top: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(_emoji, style: const TextStyle(fontSize: 34)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Custom ${widget.orderType}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Design your perfect ${widget.orderType.toLowerCase()}',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main form with all the order fields
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: '✨ ${widget.orderType} Preferences'),
                    const SizedBox(height: 14),

                    // Flavor chips — tap one to select it
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Flavor *'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _flavors.map((flavor) {
                              final selected = _selectedFlavor == flavor;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedFlavor = flavor),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppTheme.chocolate
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected
                                          ? AppTheme.chocolate
                                          : AppTheme.roseDust.withOpacity(0.5),
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.chocolate
                                                  .withOpacity(0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    flavor,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.chocolate.withOpacity(0.7),
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Size options — tap one to select it
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Size *'),
                          const SizedBox(height: 10),
                          ..._sizes.map((size) {
                            final selected = _selectedSize == size;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedSize = size),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppTheme.chocolate
                                      : AppTheme.cream,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppTheme.chocolate
                                        : AppTheme.roseDust.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      size: 18,
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.chocolate.withOpacity(0.4),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      size,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : AppTheme.darkChoco,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Number of layers — only shown for cakes, not cupcakes
                    if (widget.orderType == 'Cake') ...[
                      _FormCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Number of Layers'),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$_layers layer${_layers > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: AppTheme.caramel,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _QBtn(
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (_layers > 1) setState(() => _layers--);
                                  },
                                ),
                                const SizedBox(width: 8),
                                _QBtn(
                                  icon: Icons.add,
                                  filled: true,
                                  onTap: () {
                                    if (_layers < 5) setState(() => _layers++);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Optional color theme field
                    _FormCard(
                      child: TextFormField(
                        controller: _colorThemeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Color Theme (optional)',
                          hintText: 'e.g. Pastel pink and gold',
                          prefixIcon: Icon(Icons.palette_outlined,
                              color: AppTheme.caramel.withOpacity(0.7),
                              size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional message to be written on the cake
                    _FormCard(
                      child: TextFormField(
                        controller: _messageCtrl,
                        decoration: InputDecoration(
                          labelText:
                              'Message on ${widget.orderType} (optional)',
                          hintText: 'e.g. Happy Birthday, Maria! 🎉',
                          prefixIcon: Icon(Icons.celebration_outlined,
                              color: AppTheme.caramel.withOpacity(0.7),
                              size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional reference image upload
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Reference Image (optional)'),
                          const SizedBox(height: 4),
                          Text(
                            'Upload a photo of your preferred cake design',
                            style: TextStyle(
                              color: AppTheme.chocolate.withOpacity(0.45),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickReferenceImage,
                            child: _referenceImageBytes != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        // ✅ Image.memory works on both mobile & web
                                        child: Image.memory(
                                          _referenceImageBytes!,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      // X button to remove the selected image
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _referenceImageBytes = null;
                                            _referenceImageFileName = null;
                                            _referenceImageMimeType = null;
                                          }),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppTheme.cream,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            AppTheme.roseDust.withOpacity(0.4),
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            color: AppTheme.chocolate
                                                .withOpacity(0.4),
                                            size: 32),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Tap to upload reference photo',
                                          style: TextStyle(
                                            color: AppTheme.chocolate
                                                .withOpacity(0.45),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional special notes field
                    _FormCard(
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Special Notes (optional)',
                          hintText:
                              'Allergies, special requests, design reference...',
                          prefixIcon: Icon(Icons.note_alt_outlined,
                              color: AppTheme.caramel.withOpacity(0.7),
                              size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Delivery date, time, and address fields
                    const _SectionHeader(title: '🚚 Delivery Details'),
                    const SizedBox(height: 14),

                    _FormCard(
                      child: Column(
                        children: [
                          _TapRow(
                            label: 'Delivery Date *',
                            value: _formattedDate,
                            icon: Icons.calendar_today_outlined,
                            onTap: _pickDate,
                          ),
                          const Divider(height: 1, color: Color(0xFFEEE0D4)),
                          const SizedBox(height: 12),
                          _TapRow(
                            label: 'Delivery Time *',
                            value: _formattedTime,
                            icon: Icons.access_time_outlined,
                            onTap: _pickTime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _FormCard(
                      child: TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Delivery Address *',
                          prefixIcon: Icon(Icons.location_on_outlined,
                              color: AppTheme.caramel.withOpacity(0.7),
                              size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Delivery address is required'
                            : null,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Info box telling the user what happens after they submit
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppTheme.gold.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'After submitting, our team will review your order and set a price. '
                              'You\'ll see the quote in "My Custom Orders" in your profile.',
                              style: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.7),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit button — shows a loading spinner while submitting
                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_emoji,
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Submit Custom Order',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
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

// Helper Widgets

// Bold section title shown above each group of fields
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppTheme.darkChoco));
}

// Small label shown above each input field
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: AppTheme.chocolate.withOpacity(0.55),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3));
}

// White rounded card that wraps each form section
class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
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
        child: child,
      );
}

// A tappable row used for picking date and time
class _TapRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _TapRow(
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
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
                        fontWeight:
                            isPlaceholder ? FontWeight.w400 : FontWeight.w600)),
              ])),
          Icon(Icons.arrow_drop_down, color: AppTheme.caramel.withOpacity(0.6)),
        ]),
      ),
    );
  }
}

// Small + and - buttons used to change the number of cake layers
class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _QBtn({required this.icon, required this.onTap, this.filled = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: filled ? AppTheme.chocolate : AppTheme.cream,
            borderRadius: BorderRadius.circular(10),
            border: filled
                ? null
                : Border.all(color: AppTheme.roseDust.withOpacity(0.4)),
          ),
          child: Icon(icon,
              size: 18, color: filled ? Colors.white : AppTheme.chocolate),
        ),
      );
}
