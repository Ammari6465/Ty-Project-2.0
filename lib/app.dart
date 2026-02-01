import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_map.dart';
import 'screens/volunteer_hub.dart';
import 'screens/resource_tracker.dart';
import 'screens/notifications_screen.dart';
import 'screens/ai_predictor.dart';
import 'screens/analytics_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_user_management.dart';
import 'models/user_role.dart';
import 'widgets/role_gate.dart';

class DisasterLinkApp extends StatelessWidget {
  const DisasterLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DisasterLink',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
  scaffoldBackgroundColor: Colors.grey[50],
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size.fromHeight(48)),
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 14.0)),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (c) => const LoginScreen(),
        '/register': (c) => const RegisterScreen(),
        '/dashboard': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.ngo, UserRole.volunteer, UserRole.guest},
              child: DashboardMapScreen(),
            ),
        '/volunteer': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.volunteer},
              child: VolunteerHubScreen(),
            ),
        '/resources': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.ngo, UserRole.volunteer},
              child: ResourceTrackerScreen(),
            ),
        '/notifications': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.ngo, UserRole.volunteer},
              child: NotificationsScreen(),
            ),
        '/ai': (c) => const RoleGate(
              allowed: {UserRole.admin},
              child: AIPredictorScreen(),
            ),
        '/analytics': (c) => const RoleGate(
              allowed: {UserRole.admin, UserRole.ngo},
              child: AnalyticsScreen(),
            ),
        '/admin/users': (c) => const RoleGate(
              allowed: {UserRole.admin},
              child: AdminUserManagementScreen(),
            ),
      },
    );
  }
}
