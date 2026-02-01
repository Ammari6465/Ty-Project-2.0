import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../models/user_role.dart';
import '../services/role_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/modern_card.dart';
import '../widgets/balance_indicator.dart';

class ModernDashboard extends StatefulWidget {
  const ModernDashboard({super.key});

  @override
  State<ModernDashboard> createState() => _ModernDashboardState();
}

class _ModernDashboardState extends State<ModernDashboard> {
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _userRole = RoleService.instance.getRole();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // Modern AppBar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppTheme.purpleGradient),
                child: Stack(
                  children: [
                    Positioned(
                      top: -100,
                      right: -100,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: -50,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'DisasterLink',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome, ${_userRole?.label ?? "User"}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          // Main content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Balance indicators
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      BalanceIndicator(
                        label: 'Tasks\nRemaining',
                        amount: '12',
                        color: AppTheme.primaryPurple,
                        icon: Icons.assignment,
                      ),
                      BalanceIndicator(
                        label: 'Volunteers\nActive',
                        amount: '34',
                        color: AppTheme.successGreen,
                        icon: Icons.people,
                      ),
                      BalanceIndicator(
                        label: 'Resources\nAvailable',
                        amount: '28',
                        color: AppTheme.warningOrange,
                        icon: Icons.inventory,
                      ),
                    ],
                  ),
                ),
                // Quick access header
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                // Volunteer Hub
                ModernCard(
                  title: 'Volunteer Hub',
                  subtitle: 'Manage and coordinate volunteers',
                  icon: Icons.volunteer_activism,
                  iconColor: AppTheme.successGreen,
                  badge: '12',
                  badgeColor: AppTheme.successGreen,
                  onTap: () => Navigator.pushNamed(context, '/volunteer'),
                ),
                // Resource Tracker
                ModernCard(
                  title: 'Resource Tracker',
                  subtitle: 'Monitor available resources',
                  icon: Icons.inventory_2,
                  iconColor: AppTheme.warningOrange,
                  badge: '28',
                  badgeColor: AppTheme.warningOrange,
                  onTap: () => Navigator.pushNamed(context, '/resources'),
                ),
                // Notifications
                ModernCard(
                  title: 'Notifications',
                  subtitle: 'View alerts and updates',
                  icon: Icons.notifications_active,
                  iconColor: AppTheme.errorRed,
                  badge: '5',
                  badgeColor: AppTheme.errorRed,
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
                // AI Predictor (Admin only)
                if (_userRole == UserRole.admin)
                  ModernCard(
                    title: 'AI Predictor',
                    subtitle: 'Predict disaster hotspots',
                    icon: Icons.analytics,
                    iconColor: AppTheme.primaryPurple,
                    onTap: () => Navigator.pushNamed(context, '/ai'),
                  ),
                // Analytics (Admin/NGO)
                if (_userRole == UserRole.admin || _userRole == UserRole.ngo)
                  ModernCard(
                    title: 'Analytics',
                    subtitle: 'View detailed statistics',
                    icon: Icons.bar_chart,
                    iconColor: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/analytics'),
                  ),
                // Admin Panel (Admin only)
                if (_userRole == UserRole.admin)
                  ModernCard(
                    title: 'User Management',
                    subtitle: 'Manage system users',
                    icon: Icons.admin_panel_settings,
                    iconColor: AppTheme.errorRed,
                    onTap: () => Navigator.pushNamed(context, '/admin/users'),
                  ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency alert triggered!')),
          );
        },
        backgroundColor: AppTheme.errorRed,
        icon: const Icon(Icons.warning),
        label: const Text('Emergency'),
      ),
    );
  }
}
