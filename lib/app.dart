import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/modern_dashboard.dart';
import 'screens/volunteer_hub.dart';
import 'screens/resource_tracker.dart';
import 'screens/notifications_screen.dart';
import 'screens/ai_predictor.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_map.dart';
import 'screens/register_screen.dart';
import 'screens/admin_user_management.dart';
import 'models/user_role.dart';
import 'widgets/role_gate.dart';
import 'theme/app_theme.dart';

class DisasterLinkApp extends StatelessWidget {
  const DisasterLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DisasterLink',
      theme: AppTheme.lightTheme(),
      initialRoute: '/login',
      routes: {
        '/login': (c) => const LoginScreen(),
        '/register': (c) => const RegisterScreen(),
        '/dashboard': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.ngo, UserRole.volunteer, UserRole.guest},
              child: ModernDashboard(),
            ),
        '/volunteer': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.volunteer, UserRole.ngo, UserRole.guest},
              child: VolunteerHubScreen(),
            ),
        '/resources': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.ngo, UserRole.volunteer, UserRole.guest},
              child: ResourceTrackerScreen(),
            ),
        '/notifications': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.ngo, UserRole.volunteer, UserRole.guest},
              child: NotificationsScreen(),
            ),
        '/ai': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.guest},
              child: AIPredictorScreen(),
            ),
        '/analytics': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.ngo, UserRole.guest},
              child: AnalyticsScreen(),
            ),
        '/map': (c) => const DashboardMapScreen(),
        '/admin': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.guest},
              child: AdminUserManagementScreen(),
            ),
      },
    );
  }
}
