import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fullName = AuthService.currentUser?['fullName'] ?? 'Guest';
    final firstName = fullName.split(' ').first;
    final dateCreated = AuthService.currentUser?['dateCreated'] ?? '';

    // Real notifications based on actual user session
    final List<_NotifItem> notifications = [
      _NotifItem(
        icon: Icons.waving_hand_rounded,
        iconColor: const Color(0xFFE8A838),
        title: 'Welcome to Sweet Cengsations!',
        message:
            'Hello, $firstName! Good day! We\'re so happy to have you here. Browse our freshly baked treats and place your first order today!',
        time: dateCreated.isNotEmpty ? _formatDate(dateCreated) : 'Just now',
        isNew: true,
      ),
      _NotifItem(
        icon: Icons.storefront_outlined,
        iconColor: const Color(0xFF4A90D9),
        title: 'Your account is ready!',
        message:
            'Your Sweet Cengsations account has been set up successfully. Start exploring our menu and enjoy sweet treats delivered to you!',
        time: dateCreated.isNotEmpty ? _formatDate(dateCreated) : 'Just now',
        isNew: true,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
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
                    Text('Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        )),
                    SizedBox(height: 2),
                    Text('Stay updated with your orders',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        )),
                  ],
                ),
              ],
            ),
          ),

          // ── Notification List ────────────────────────────
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64,
                            color: AppTheme.chocolate.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text('No notifications yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.chocolate.withOpacity(0.5),
                            )),
                        const SizedBox(height: 6),
                        Text('We\'ll notify you about your orders here.',
                            style: TextStyle(
                              color: AppTheme.chocolate.withOpacity(0.35),
                              fontSize: 13,
                            )),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, i) {
                      final notif = notifications[i];
                      return _NotifCard(notif: notif);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';

      final months = [
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
      return 'Recently';
    }
  }
}

// ── Notification Card ─────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final _NotifItem notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chocolate.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon bubble
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: notif.iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(notif.icon, color: notif.iconColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(notif.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkChoco,
                          )),
                    ),
                    if (notif.isNew)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF7D),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notif.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.chocolate.withOpacity(0.6),
                      height: 1.5,
                    )),
                const SizedBox(height: 6),
                Text(notif.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.chocolate.withOpacity(0.35),
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Item Model ───────────────────────────────────────────────────
class _NotifItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String time;
  final bool isNew;

  const _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    required this.isNew,
  });
}
