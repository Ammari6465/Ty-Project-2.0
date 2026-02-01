import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigateAfterClose(BuildContext context, String routeName) {
    final navigator = Navigator.of(context);
    final current = ModalRoute.of(context)?.settings.name;
    // If we're already on the target route, just close the drawer.
    if (current == routeName) {
      navigator.pop();
      return;
    }
    // Close the drawer first, then delay navigation slightly so the drawer
    // layout/animation completes before pushing a new route.
    navigator.pop();
    Future.delayed(const Duration(milliseconds: 250), () {
      // Guard against navigation if the widget tree changed radically.
      if (navigator.mounted) {
        navigator.pushReplacementNamed(routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserRole>(
      valueListenable: RoleService.instance.role,
      builder: (context, role, _) {
        return Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 28, child: Icon(Icons.link)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('DisasterLink', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Role: ${role.label}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      )
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Dashboard Map'),
                  onTap: () => _navigateAfterClose(context, '/dashboard'),
                ),
                if (RoleService.canAccessRoute(role, '/volunteer'))
                  ListTile(
                    leading: const Icon(Icons.group),
                    title: const Text('Volunteer Hub'),
                    onTap: () => _navigateAfterClose(context, '/volunteer'),
                  ),
                if (RoleService.canAccessRoute(role, '/resources'))
                  ListTile(
                    leading: const Icon(Icons.inventory),
                    title: const Text('Resource Tracker'),
                    onTap: () => _navigateAfterClose(context, '/resources'),
                  ),
                if (RoleService.canAccessRoute(role, '/notifications'))
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    onTap: () => _navigateAfterClose(context, '/notifications'),
                  ),
                if (RoleService.canAccessRoute(role, '/ai'))
                  ListTile(
                    leading: const Icon(Icons.memory),
                    title: const Text('AI Predictor'),
                    onTap: () => _navigateAfterClose(context, '/ai'),
                  ),
                if (RoleService.canAccessRoute(role, '/analytics'))
                  ListTile(
                    leading: const Icon(Icons.query_stats),
                    title: const Text('Analytics'),
                    onTap: () => _navigateAfterClose(context, '/analytics'),
                  ),
                if (role == UserRole.admin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('User Management'),
                    onTap: () => _navigateAfterClose(context, '/admin/users'),
                  ),
                const Spacer(),
                if (role == UserRole.guest)
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Back to Login'),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      Future.microtask(() => navigator.pushNamedAndRemoveUntil('/login', (route) => false));
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      await AuthService.instance.signOut();
                      RoleService.instance.setRole(UserRole.guest);
                      if (navigator.mounted) {
                        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
