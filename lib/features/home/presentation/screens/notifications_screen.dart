import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/providers/supabase_provider.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              final supabase = ref.read(supabaseClientProvider);
              final user = supabase.auth.currentUser;
              if (user != null) {
                await supabase
                    .from('notifications')
                    .update({'is_read': true})
                    .eq('user_id', user.id);
              }
            },
            child: const Text('Mark all as read', style: TextStyle(color: Colors.deepPurpleAccent)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isRead = n['is_read'] as bool;
              final createdAt = DateTime.parse(n['created_at']);

              return InkWell(
                onTap: () async {
                  if (!isRead) {
                    await ref.read(supabaseClientProvider)
                        .from('notifications')
                        .update({'is_read': true})
                        .eq('id', n['id']);
                  }
                  // Navigate based on type if needed
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead ? Colors.white.withOpacity(0.05) : Colors.deepPurpleAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getIconColor(n['type']).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIcon(n['type']), color: _getIconColor(n['type']), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n['message'],
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeago.format(createdAt),
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'approval_request': return Icons.pending_actions;
      case 'property_approved': return Icons.check_circle_outline;
      case 'promotion_request': return Icons.trending_up;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'approval_request': return Colors.orange;
      case 'property_approved': return Colors.green;
      case 'promotion_request': return Colors.blue;
      default: return Colors.deepPurpleAccent;
    }
  }
}
