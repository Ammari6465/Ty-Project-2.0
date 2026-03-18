import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../services/firestore_service.dart';
import '../models/resource_model.dart';
import '../models/volunteer_model.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/modern_stat_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Analytics & Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        titleTextStyle: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview Status',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<VolunteerModel>>(
                    stream: FirestoreService.instance.streamVolunteers(),
                    builder: (context, volSnapshot) {
                      final volunteers = volSnapshot.data ?? [];
                      final activeVolunteers = volunteers.where((v) => v.availability == 'Available').length;
                      
                      return StreamBuilder<List<ResourceModel>>(
                        stream: FirestoreService.instance.streamResources(),
                        builder: (context, resSnapshot) {
                          final resources = resSnapshot.data ?? [];
                          final lowStock = resources.where((r) => r.quantity < 10).length;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ModernStatCard(
                                      label: 'Active Volunteers',
                                      value: activeVolunteers.toString(),
                                      icon: Icons.volunteer_activism,
                                      color: AppTheme.successGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ModernStatCard(
                                      label: 'Total Volunteers',
                                      value: volunteers.length.toString(),
                                      icon: Icons.group,
                                      color: AppTheme.primaryBrand,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ModernStatCard(
                                      label: 'Total Resources',
                                      value: resources.length.toString(),
                                      icon: Icons.inventory_2,
                                      color: AppTheme.accentBrand,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ModernStatCard(
                                      label: 'Low Stock Alerts',
                                      value: lowStock.toString(),
                                      icon: Icons.warning_amber_rounded,
                                      color: lowStock > 0 ? AppTheme.errorRed : AppTheme.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 16),
                  GlassListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen),
                    ),
                    title: const Text('System Online'),
                    subtitle: const Text('All modules functioning normally'),
                  ),
                  const SizedBox(height: 12),
                  // Placeholder for recent activity list
                  // In a real app, this would come from an activity log stream
                  GlassListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBrand.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.update, color: AppTheme.accentBrand),
                    ),
                    title: const Text('Database Synced'),
                    subtitle: const Text('Last sync: Just now'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
