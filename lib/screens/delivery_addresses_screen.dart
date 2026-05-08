import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/user_session.dart';

// Screen where the user can view, add, and delete their saved delivery addresses
class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  State<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  late List<String> _addresses;
  late String _selectedAddress;
  final _addCtrl = TextEditingController();

  // Loads the user's saved addresses and currently selected address on startup
  @override
  void initState() {
    super.initState();
    _addresses = List<String>.from(
        UserSession.instance.currentUser?.savedAddresses ?? []);
    _selectedAddress = UserSession.instance.selectedDeliveryAddress;
  }

  // Cleans up the text controller when the screen is closed
  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  // Sets the tapped address as the default and shows a confirmation message
  void _selectAddress(String address) {
    setState(() => _selectedAddress = address);
    UserSession.instance.setSelectedDeliveryAddress(address);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(
        children: [
          Text('✅', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text('Default address updated!',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // Opens a bottom sheet with a text field to add a new address
  void _showAddDialog() {
    _addCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Address',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkChoco)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addCtrl,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                      'Enter full address (e.g. 123 Mango St., Cebu City)',
                  hintStyle: TextStyle(
                      color: AppTheme.chocolate.withOpacity(0.4), fontSize: 14),
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: AppTheme.caramel.withOpacity(0.7), size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppTheme.roseDust.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppTheme.roseDust.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.chocolate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final text = _addCtrl.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx);
                    setState(() {
                      if (!_addresses.contains(text)) {
                        _addresses.add(text);
                        UserSession.instance.addSavedAddress(text);
                      }
                      // Auto-select if this is the first address added
                      if (_addresses.length == 1 || _selectedAddress.isEmpty) {
                        _selectedAddress = text;
                        UserSession.instance.setSelectedDeliveryAddress(text);
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Row(
                        children: [
                          Text('📍', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Address added!',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.chocolate,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.chocolate,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Save Address',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Shows a confirmation dialog before deleting an address
  void _confirmDelete(String address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Address?',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppTheme.darkChoco)),
        content: Text(
          'Are you sure you want to remove this address?\n\n"$address"',
          style: const TextStyle(color: AppTheme.chocolate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.chocolate)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _addresses.remove(address);
                UserSession.instance.removeSavedAddress(address);
                // If the deleted address was the default, switch to the next one
                if (_selectedAddress == address) {
                  _selectedAddress =
                      _addresses.isNotEmpty ? _addresses.first : '';
                  if (_selectedAddress.isNotEmpty) {
                    UserSession.instance
                        .setSelectedDeliveryAddress(_selectedAddress);
                  }
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Address removed.',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: Colors.orange.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // Gradient header with back button and add button
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
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery Addresses 📍',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Tap to select your default address',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showAddDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // Info banner shown when a default address is already selected
          if (_selectedAddress.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your selected address will auto-fill when placing orders. '
                      'Tap any address below to set it as default.',
                      style: TextStyle(
                          color: AppTheme.chocolate.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          // Address list — shows empty state if no addresses are saved
          Expanded(
            child: _addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📍', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text('No saved addresses yet',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.chocolate.withOpacity(0.5))),
                        const SizedBox(height: 8),
                        Text('Tap the + button to add your address',
                            style: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.35),
                                fontSize: 13)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Address'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.chocolate,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    itemBuilder: (_, i) {
                      final address = _addresses[i];
                      final isSelected = address == _selectedAddress;

                      return GestureDetector(
                        onTap: () => _selectAddress(address),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            // Highlighted border when this address is the default
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.chocolate
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.chocolate
                                      .withOpacity(isSelected ? 0.12 : 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Location icon — filled when selected, outlined when not
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.chocolate
                                      : AppTheme.cream,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.location_on_rounded
                                      : Icons.location_on_outlined,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.chocolate.withOpacity(0.4),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // "Default" badge shown only on the selected address
                                    Row(
                                      children: [
                                        if (isSelected)
                                          Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.chocolate,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text('✓ Default',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      address,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: AppTheme.darkChoco,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (!isSelected) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tap to set as default',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.chocolate
                                                .withOpacity(0.4)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // X button to remove this address
                              GestureDetector(
                                onTap: () => _confirmDelete(address),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Add New Address button at the bottom — only shown when there are existing addresses
          if (_addresses.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add New Address',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.chocolate,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
