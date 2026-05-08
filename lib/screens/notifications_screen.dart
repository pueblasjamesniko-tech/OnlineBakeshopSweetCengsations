import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../models/user_session.dart';

// This screen shows all the notifications for the user.
// Like a message inbox that tells you updates about your orders!
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

// A list that holds all the notifications from the server
// True means we are still loading — show a spinner
class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  // Runs automatically when the screen opens — go fetch the notifications!
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Asks the server for this user's notifications and saves them
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId =
          int.tryParse(UserSession.instance.currentUser?.id ?? '') ?? 0;
      if (userId > 0) {
        final result = await ApiService.getNotificationsByUser(userId);
        setState(() {
          _notifications = result;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Marks every single notification as "read" all at once
  Future<void> _markAllAsRead() async {
    await ApiService.markAllNotificationsAsRead();
    await _loadNotifications();
  }

  // Marks one specific notification as "read" when the user taps it
  Future<void> _markAsRead(dynamic notificationId) async {
    await ApiService.markNotificationAsRead(notificationId);
    await _loadNotifications();
  }

  // Deletes one notification (when the user swipes it away)
  Future<void> _deleteNotification(dynamic notificationId) async {
    await ApiService.deleteNotification(notificationId);
    await _loadNotifications();
  }

  // Turns a date string into a human-friendly time like "5m ago" or "2d ago"
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now'; // Less than a minute
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  // Returns an emoji that matches the type of notification
  // Like a sticker to quickly show what the notification is about
  String _getNotifEmoji(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'order':
        return '🛍️';
      case 'custom':
        return '🎂';
      case 'payment':
        return '💳';
      case 'promo':
        return '🎉';
      default:
        return '🔔';
    }
  }

  // Checks if there is at least one unread notification in the list
  // Used to decide whether to show the "Read all" button
  bool _hasUnread() {
    return _notifications.any((n) => n['isRead'] == false || n['isRead'] == 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          // Top header bar with title and "Read all" button
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: AppTheme.chocolateGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
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
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Notifications 🔔',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // "Read all" button — only shows when there are unread notifications
                if (_hasUnread())
                  GestureDetector(
                    onTap: _markAllAsRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Read all',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main content — spinner, empty message, or the notifications list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.chocolate),
                  )
                // No notifications? Show a friendly empty message
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔔', style: TextStyle(fontSize: 60)),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.chocolate.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We\'ll notify you about your orders here.',
                              style: TextStyle(
                                color: AppTheme.chocolate.withOpacity(0.35),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    // Has notifications? Show them as a scrollable list
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: AppTheme.chocolate,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          itemCount: _notifications.length,
                          itemBuilder: (_, i) {
                            final notif = _notifications[i];
                            final isRead =
                                notif['isRead'] == true || notif['isRead'] == 1;
                            final notifId = notif['notificationId'];

                            return Dismissible(
                              key: Key(notifId.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.white, size: 24),
                              ),
                              onDismissed: (_) => _deleteNotification(notifId),
                              child: GestureDetector(
                                onTap: () {
                                  if (!isRead) _markAsRead(notifId);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isRead
                                        ? Colors.white
                                        : AppTheme.chocolate.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: isRead
                                        ? null
                                        : Border.all(
                                            color: AppTheme.chocolate
                                                .withOpacity(0.15)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.chocolate
                                            .withOpacity(0.06),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Emoji icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppTheme.cream,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getNotifEmoji(
                                                notif['type']?.toString()),
                                            style:
                                                const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Text content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif['title']
                                                            ?.toString() ??
                                                        'Notification',
                                                    style: TextStyle(
                                                      fontWeight: isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.w800,
                                                      fontSize: 14,
                                                      color: AppTheme.darkChoco,
                                                    ),
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: AppTheme.caramel,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notif['body']?.toString() ??
                                                  notif['message']
                                                      ?.toString() ??
                                                  '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.chocolate
                                                    .withOpacity(0.6),
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _formatDate(notif['createdAt']
                                                  ?.toString()),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.chocolate
                                                    .withOpacity(0.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
}
