import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
              bottom: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 18),
                const Text(
                  '🍰 Help & Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Everything you need to know about\nSweet Cengsations',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.chocolate.withOpacity(0.07),
                          AppTheme.caramel.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppTheme.caramel.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎂 Welcome to Sweet Cengsations!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkChoco,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sweet Cengsations is your go-to artisan bakeshop for freshly baked cakes, '
                          'cupcakes, and other sweet delights. Whether you\'re celebrating a birthday, '
                          'anniversary, or simply treating yourself, we\'re here to make every occasion '
                          'extra special with our handcrafted goodies made with love.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.chocolate.withOpacity(0.7),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: How to Order
                  _SectionTitle('🛒 How to Place a Regular Order'),
                  const SizedBox(height: 12),
                  _StepCard(
                    step: '1',
                    title: 'Browse our products',
                    description:
                        'Scroll through the Home screen to explore all available cakes, cupcakes, and pastries.',
                  ),
                  _StepCard(
                    step: '2',
                    title: 'Add to Cart or Place Now',
                    description:
                        'Tap on a product to view details. You can add it to your cart for later or place the order immediately.',
                  ),
                  _StepCard(
                    step: '3',
                    title: 'Fill in delivery details',
                    description:
                        'Enter your preferred delivery date, time, and address before confirming.',
                  ),
                  _StepCard(
                    step: '4',
                    title: 'Track your order',
                    description:
                        'Go to Profile → My Orders to see the status of all your placed orders in real time.',
                  ),

                  const SizedBox(height: 24),

                  // Section: Custom Orders
                  _SectionTitle('✨ How Custom Orders Work'),
                  const SizedBox(height: 12),
                  _StepCard(
                    step: '1',
                    title: 'Choose Cake or Cupcake',
                    description:
                        'On the Home screen, tap "Custom Cake" or "Custom Cupcake" to start designing your dream order.',
                  ),
                  _StepCard(
                    step: '2',
                    title: 'Fill in your preferences',
                    description:
                        'Select your flavor, size, color theme, message on cake, number of layers, and any special notes.',
                  ),
                  _StepCard(
                    step: '3',
                    title: 'Submit and wait for a quote',
                    description:
                        'After submitting, our team will review your request and set a price. This usually takes 1–2 business days.',
                  ),
                  _StepCard(
                    step: '4',
                    title: 'Check your quote',
                    description:
                        'Once priced, you\'ll see the quoted amount under Profile → My Custom Orders. Contact us to confirm payment.',
                  ),
                  _StepCard(
                    step: '5',
                    title: 'Track until delivery',
                    description:
                        'After payment, your order status will update as it moves through Preparing → Ready for Pickup → Delivered.',
                  ),

                  const SizedBox(height: 24),

                  // Section: Order Statuses
                  _SectionTitle('📋 Understanding Order Statuses'),
                  const SizedBox(height: 12),
                  _StatusInfoCard(
                    color: const Color(0xFF795548),
                    emoji: '⏳',
                    status: 'Awaiting Quote',
                    description:
                        'Custom orders only. Our team is reviewing your design and will set a price soon.',
                  ),
                  _StatusInfoCard(
                    color: const Color(0xFF0288D1),
                    emoji: '💬',
                    status: 'Quoted',
                    description:
                        'A price has been set for your custom order. Please confirm payment with us.',
                  ),
                  _StatusInfoCard(
                    color: const Color(0xFFE8A838),
                    emoji: '🕐',
                    status: 'Pending',
                    description:
                        'Your order is confirmed and waiting to be prepared by our team.',
                  ),
                  _StatusInfoCard(
                    color: const Color(0xFF1565C0),
                    emoji: '👨‍🍳',
                    status: 'Preparing',
                    description:
                        'Our bakers are crafting your order right now!',
                  ),
                  _StatusInfoCard(
                    color: const Color(0xFF6A1B9A),
                    emoji: '📦',
                    status: 'Ready for Pickup',
                    description:
                        'Your order is packed and ready to be picked up or delivered.',
                  ),
                  _StatusInfoCard(
                    color: const Color(0xFF4CAF50),
                    emoji: '✅',
                    status: 'Delivered',
                    description:
                        'Your order has been delivered. Enjoy your sweet treats!',
                  ),
                  _StatusInfoCard(
                    color: const Color(0xFFD32F2F),
                    emoji: '❌',
                    status: 'Rejected',
                    description:
                        'Your order was rejected. This may be due to availability or design concerns. Please contact us.',
                  ),

                  const SizedBox(height: 24),

                  // Section: FAQs
                  _SectionTitle('❓ Frequently Asked Questions'),
                  const SizedBox(height: 12),
                  _FaqCard(
                    question: 'Can I cancel my order?',
                    answer:
                        'Once an order is being prepared, it cannot be cancelled. Please contact us as early as possible if you need to make changes.',
                  ),
                  _FaqCard(
                    question: 'How long does delivery take?',
                    answer:
                        'Delivery times vary depending on your chosen delivery date and location. We will do our best to deliver on time.',
                  ),
                  _FaqCard(
                    question:
                        'Can I change my delivery address after ordering?',
                    answer:
                        'Please contact us immediately if you need to change your delivery address. Changes can only be made before the order starts being prepared.',
                  ),
                  _FaqCard(
                    question: 'How do I pay for my custom order?',
                    answer:
                        'After we set a quoted price, please visit our store or contact us to arrange payment. We accept cash and online transfers.',
                  ),
                  _FaqCard(
                    question: 'What if my order is rejected?',
                    answer:
                        'If your custom order is rejected, it may be due to design complexity or ingredient availability. Please reach out to us for alternatives.',
                  ),

                  const SizedBox(height: 24),

                  // Contact info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.chocolate,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '📞 Contact Us',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Have more questions or need assistance? We\'d love to hear from you!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ContactRow(
                            icon: Icons.storefront_outlined,
                            label: 'Isuya Mactan Lapu-lapu City'),
                        const SizedBox(height: 8),
                        _ContactRow(
                            icon: Icons.schedule_outlined,
                            label: 'Contact us: 09454975134'),
                        const SizedBox(height: 8),
                        _ContactRow(
                            icon: Icons.email_outlined,
                            label: 'sweetcengsations@gmail.com'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: Text(
                      'Sweet Cengsations v1.0.0 ✦\nMade with heart for every sweet occasion',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.chocolate.withOpacity(0.3),
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.darkChoco,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.chocolate,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkChoco,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.chocolate.withOpacity(0.6),
                    height: 1.5,
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

class _StatusInfoCard extends StatelessWidget {
  final Color color;
  final String emoji;
  final String status;
  final String description;

  const _StatusInfoCard({
    required this.color,
    required this.emoji,
    required this.status,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$emoji $status',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.chocolate.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqCard({required this.question, required this.answer});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkChoco,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.chocolate.withOpacity(0.4),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.answer,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.chocolate.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
