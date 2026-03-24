import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

  static const List<_StatusStep> _steps = [
    _StatusStep(
      icon: Icons.access_time_rounded,
      label: 'Pending',
      description: 'We received your order and\nit\'s waiting to be confirmed.',
      color: Color(0xFFE8A838),
    ),
    _StatusStep(
      icon: Icons.soup_kitchen_outlined,
      label: 'Preparing',
      description: 'The baker are crafting\nyour sweet treats!',
      color: Color(0xFF4A90D9),
    ),
    _StatusStep(
      icon: Icons.inventory_2_outlined,
      label: 'Ready for Pickup',
      description: 'Your order is packed and\nfresh, ready for you!',
      color: Color(0xFF7B5EA7),
    ),
    _StatusStep(
      icon: Icons.check_circle_outline_rounded,
      label: 'Delivered',
      description: 'Order delivered! Enjoy your sweets.',
      color: Color(0xFF4CAF7D),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          //Header
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
                      'Order Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track how your order progresses',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          //Steps
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: List.generate(_steps.length, (i) {
                  final step = _steps[i];
                  final isLast = i == _steps.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //Left: dot + line
                      Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: step.color.withOpacity(0.12),
                              border: Border.all(
                                color: step.color.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                step.icon,
                                color: step.color,
                                size: 26,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2.5,
                              height: 60,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    step.color.withOpacity(0.4),
                                    _steps[i + 1].color.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 18),

                      //Right: label + description
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: step.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  step.label,
                                  style: TextStyle(
                                    color: step.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.chocolate.withOpacity(0.6),
                                  height: 1.5,
                                ),
                              ),
                              if (!isLast) const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStep {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}
