import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/cart_item.dart';
import '../../../models/user_session.dart';
import '../../../services/api_service.dart';

class CustomOrderScreen extends StatefulWidget {
  final String orderType; // "Cake" or "Cupcake"
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

  // ── Form controllers ───────────────────────────────────────
  String? _selectedFlavor;
  String? _selectedSize;
  final _colorThemeCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  int _layers = 1;
  final _notesCtrl = TextEditingController();
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;
  final _addressCtrl = TextEditingController();

  // ── Options ────────────────────────────────────────────────
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

  List<String> get _sizes => widget.orderType == 'Cake'
      ? [
          '6 inch (6–8 pax)',
          '8 inch (10–12 pax)',
          '10 inch (15–20 pax)',
          '12 inch (25–30 pax)'
        ]
      : ['6 pieces', '12 pieces', '24 pieces', '36 pieces'];

  String get _emoji => widget.orderType == 'Cake' ? '🎂' : '🧁';

  // ── Formatted helpers ──────────────────────────────────────
  String get _formattedDate => _deliveryDate == null
      ? 'Select date'
      : '${_deliveryDate!.year}-${_deliveryDate!.month.toString().padLeft(2, '0')}-${_deliveryDate!.day.toString().padLeft(2, '0')}';

  String get _formattedTime =>
      _deliveryTime == null ? 'Select time' : _deliveryTime!.format(context);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Select Delivery Date',
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

    final userId =
        int.tryParse(UserSession.instance.currentUser?.id ?? '0') ?? 0;

    // Debug: print what we're sending
    print('=== CUSTOM ORDER SUBMIT ===');
    print('userId: $userId');
    print('orderType: ${widget.orderType}');
    print('flavor: $_selectedFlavor');
    print('size: $_selectedSize');
    print(
        'colorTheme: ${_colorThemeCtrl.text.trim().isEmpty ? 'N/A' : _colorThemeCtrl.text.trim()}');
    print('messageOnCake: ${_messageCtrl.text.trim()}');
    print('numberOfLayers: ${widget.orderType == 'Cake' ? _layers : 1}');
    print('specialNotes: ${_notesCtrl.text.trim()}');
    print('deliveryDate: $_formattedDate');
    print('deliveryTime: $_formattedTime');
    print('deliveryAddress: ${_addressCtrl.text.trim()}');
    print('===========================');

    final result = await ApiService.createCustomOrder(
      userId: userId,
      orderType: widget.orderType,
      flavor: _selectedFlavor!,
      size: _selectedSize!,
      // Send 'N/A' if color theme is empty so backend doesn't reject it
      colorTheme: _colorThemeCtrl.text.trim().isEmpty
          ? 'N/A'
          : _colorThemeCtrl.text.trim(),
      messageOnCake: _messageCtrl.text.trim(),
      // Always send numberOfLayers — cupcakes default to 1
      numberOfLayers: widget.orderType == 'Cake' ? _layers : 1,
      specialNotes:
          _notesCtrl.text.trim().isEmpty ? 'None' : _notesCtrl.text.trim(),
      deliveryDate: _formattedDate,
      deliveryTime: _formattedTime,
      deliveryAddress: _addressCtrl.text.trim(),
    );

    print('CUSTOM ORDER RESULT: $result');

    setState(() => _isSubmitting = false);

    if (!mounted) return;

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
          // ── App Bar ──────────────────────────────────────────
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
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
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

          // ── Form ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══════════════════════════════════════════
                    // SECTION: Preferences
                    // ═══════════════════════════════════════════
                    _SectionHeader(title: '✨ ${widget.orderType} Preferences'),
                    const SizedBox(height: 14),

                    // Flavor picker
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

                    // Size picker
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

                    // Number of Layers (Cake only)
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

                    // Color Theme
                    _FormCard(
                      child: TextFormField(
                        controller: _colorThemeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Color Theme (optional)',
                          hintText: 'e.g. Pastel pink and gold',
                          prefixIcon: Icon(
                            Icons.palette_outlined,
                            color: AppTheme.caramel.withOpacity(0.7),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Message on Cake
                    _FormCard(
                      child: TextFormField(
                        controller: _messageCtrl,
                        decoration: InputDecoration(
                          labelText:
                              'Message on ${widget.orderType} (optional)',
                          hintText: 'e.g. Happy Birthday, Maria! 🎉',
                          prefixIcon: Icon(
                            Icons.celebration_outlined,
                            color: AppTheme.caramel.withOpacity(0.7),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Special Notes
                    _FormCard(
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Special Notes (optional)',
                          hintText:
                              'Allergies, special requests, design reference...',
                          prefixIcon: Icon(
                            Icons.note_alt_outlined,
                            color: AppTheme.caramel.withOpacity(0.7),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════
                    // SECTION: Delivery Details
                    // ═══════════════════════════════════════════
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
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.caramel.withOpacity(0.7),
                            size: 20,
                          ),
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

                    // ── Info notice ──────────────────────────────
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

                    // ── Submit Button ─────────────────────────────
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
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
                                      fontWeight: FontWeight.w700,
                                    ),
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

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppTheme.darkChoco,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.chocolate.withOpacity(0.55),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TapRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TapRow({
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
            Icon(Icons.arrow_drop_down,
                color: AppTheme.caramel.withOpacity(0.6)),
          ],
        ),
      ),
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
}
