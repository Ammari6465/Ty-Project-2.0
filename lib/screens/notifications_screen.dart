import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/modern_stat_card.dart';
import '../widgets/glassmorphic_textfield.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Track subscription states
  final Set<String> _subscriptions = {'disasters', 'volunteers', 'donations'};

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
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26, 
                  blurRadius: 20, 
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Broadcast Alert',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GlassmorphicTextField(
                    controller: titleCtrl,
                    label: 'Title',
                    hint: 'Enter alert title',
                    labelColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  GlassmorphicTextField(
                    controller: bodyCtrl,
                    label: 'Message',
                    hint: 'Enter alert message',
                    labelColor: Colors.white,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.lightBrand, width: 1.5),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: AppTheme.textDark),
                      selectedItemBuilder: (BuildContext context) {
                        return ['disaster', 'volunteer', 'donation'].map((String value) {
                          return Text(
                            value == 'disaster' ? 'Disaster Update' : 
                            value == 'volunteer' ? 'Volunteer Task' : 'Donation Drive',
                            style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w500),
                          );
                        }).toList();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: AppTheme.textLight),
                        border: InputBorder.none,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryBrand),
                      items: const [
                        DropdownMenuItem(
                            value: 'disaster',
                            child: Text('Disaster Update',
                                style: TextStyle(color: AppTheme.textDark))),
                        DropdownMenuItem(
                            value: 'volunteer',
                            child: Text('Volunteer Task',
                                style: TextStyle(color: AppTheme.textDark))),
                        DropdownMenuItem(
                            value: 'donation',
                            child: Text('Donation Drive',
                                style: TextStyle(color: AppTheme.textDark))),
                      ],
                      onChanged: (val) => setState(() => selectedCategory = val!),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (titleCtrl.text.isNotEmpty && bodyCtrl.text.isNotEmpty) {
                            NotificationService.instance.sendTargetedAlert(
                              title: titleCtrl.text.trim(),
                              body: bodyCtrl.text.trim(),
                              category: selectedCategory,
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Alert Broadcasted'),
                                backgroundColor: AppTheme.successGreen));
                          }
                        },
                        child: const Text('Send Broadcast'),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
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
      case 'disaster': return AppTheme.errorRed;
      case 'volunteer': return AppTheme.warningOrange;
      case 'donation': return AppTheme.successGreen;
      default: return AppTheme.accentBrand;
    }
  }

  void _toggleSub(String topic, bool selected) {
    setState(() {
      if (selected) {
        _subscriptions.add(topic);
        NotificationService.instance.subscribeToTopic(topic);
      } else {
        _subscriptions.remove(topic);
        NotificationService.instance.unsubscribeFromTopic(topic);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(selected ? 'Subscribed to $topic' : 'Unsubscribed from $topic'),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: AppTheme.primaryBrand,
      )
    );
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will permanently delete all notification history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final snapshot = await FirebaseFirestore.instance.collection('notifications').get();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications cleared'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Alerts & Notifications',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
            onPressed: _clearAllNotifications,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                            'Disasters', 'disasters', AppTheme.errorRed),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            'Volunteers', 'volunteers', AppTheme.warningOrange),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            'Donations', 'donations', AppTheme.successGreen),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .orderBy('timestamp', descending: true)
                        .limit(50)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading alerts',
                                style: TextStyle(color: AppTheme.errorRed)));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      
                      // Filter based on active subscriptions
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final type = data['type'] as String? ?? 'info';
                        // Simple pluralization map: disaster->disasters, etc.
                        final topic = '${type}s'; 
                        return _subscriptions.contains(topic);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 64,
                                  color: AppTheme.textLight.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                docs.isEmpty ? 'No notifications yet' : 'No alerts in selected categories',
                                style: const TextStyle(
                                    color: AppTheme.textLight, fontSize: 18),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, idx) {
                          final data = filteredDocs[idx].data() as Map<String, dynamic>;
                          final title = data['title'] ?? 'No Title';
                          final body = data['body'] ?? 'No Content';
                          final type = data['type'] ?? 'info';
                          final timestamp =
                              (data['timestamp'] as Timestamp?)?.toDate();
                          final color = _getColorForType(type);

                          return GlassListTile(
                            backgroundColor: Colors.white,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: color.withOpacity(0.5), width: 1),
                              ),
                              child: Icon(_getIconForType(type), color: color),
                            ),
                            title: Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: const TextStyle(color: AppTheme.textDark),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (timestamp != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 12, color: AppTheme.textLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} • ${timestamp.day}/${timestamp.month}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {}, // Could expand details
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendDialog,
        backgroundColor: AppTheme.errorRed,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('Broadcast Alert',
            style: TextStyle(color: Colors.white)),
        elevation: 4,
      ),
    );
  }

  Widget _buildFilterChip(String label, String topic, Color color) {
    final isSelected = _subscriptions.contains(topic);
    return GestureDetector(
      onTap: () => _toggleSub(topic, !isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [
                   BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

