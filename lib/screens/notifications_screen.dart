import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  
  @override
  void initState() {
    super.initState();
    // Ensure notification services are ready when viewing this screen
    NotificationService.instance.initialize();
  }

  void _showSendDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String selectedCategory = 'disaster'; // default

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Message')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'disaster', child: Text('Disaster Update')),
                  DropdownMenuItem(value: 'volunteer', child: Text('Volunteer Task')),
                  DropdownMenuItem(value: 'donation', child: Text('Donation Drive')),
                ],
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && bodyCtrl.text.isNotEmpty) {
                  NotificationService.instance.sendTargetedAlert(
                    title: titleCtrl.text.trim(),
                    body: bodyCtrl.text.trim(),
                    category: selectedCategory,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert Broadcasted')));
                }
              },
              child: const Text('Send'),
            )
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'disaster': return Icons.warning_amber_rounded;
      case 'volunteer': return Icons.volunteer_activism;
      case 'donation': return Icons.card_giftcard;
      case 'received': return Icons.notifications_active;
      default: return Icons.info_outline;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'disaster': return Colors.red;
      case 'volunteer': return Colors.orange;
      case 'donation': return Colors.green;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications & Alerts')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
           // Subscription toggles for demo
           Padding(
             padding: const EdgeInsets.all(8.0),
             child: Wrap(
               spacing: 8.0,
               children: [
                 FilterChip(label: const Text('Disasters'), onSelected: (b) => _toggleSub('disasters', b), selected: true),
                 FilterChip(label: const Text('Volunteers'), onSelected: (b) => _toggleSub('volunteers', b), selected: true),
                 FilterChip(label: const Text('Donations'), onSelected: (b) => _toggleSub('donations', b), selected: true),
               ],
             ),
           ),
           Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No notifications yet.'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'No Title';
                    final body = data['body'] ?? 'No Content';
                    final type = data['type'] ?? 'info';
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorForType(type).withOpacity(0.2),
                        child: Icon(_getIconForType(type), color: _getColorForType(type)),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(body),
                          if (timestamp != null)
                            Text(
                              '${timestamp.hour}:${timestamp.minute} ${timestamp.day}/${timestamp.month}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
           ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendDialog,
        icon: const Icon(Icons.campaign),
        label: const Text('Broadcast'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleSub(String topic, bool sub) {
    if (sub) {
      NotificationService.instance.subscribeToTopic(topic);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subscribed to $topic')));
    } else {
      NotificationService.instance.unsubscribeFromTopic(topic);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unsubscribed from $topic')));
    }
  }
}
