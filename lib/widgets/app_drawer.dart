import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 280,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBrand.withOpacity(0.9),
                  AppTheme.accentBrand.withOpacity(0.8),
                ],
              ),
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.2))),
            ),
            child: SafeArea(
              child: ValueListenableBuilder<UserRole>(
                valueListenable: RoleService.instance.role,
                builder: (context, role, _) {
                  return Column(
                    children: [
                      _buildHeader(role),
                      Divider(color: Colors.white.withOpacity(0.2)),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            _buildGlassListTile(context, 'Dashboard Map', Icons.map, '/dashboard'),
                            if (RoleService.canAccessRoute(role, '/volunteer'))
                              _buildGlassListTile(context, 'Volunteer Hub', Icons.group, '/volunteer'),
                            if (RoleService.canAccessRoute(role, '/resources'))
                              _buildGlassListTile(context, 'Resource Tracker', Icons.inventory, '/resources'),
                            if (RoleService.canAccessRoute(role, '/notifications'))
                              _buildGlassListTile(context, 'Notifications', Icons.notifications, '/notifications'),
                            if (RoleService.canAccessRoute(role, '/ai'))
                              _buildGlassListTile(context, 'AI Predictor', Icons.memory, '/ai'),
                            if (RoleService.canAccessRoute(role, '/analytics'))
                              _buildGlassListTile(context, 'Analytics', Icons.analytics, '/analytics'),
                            // Admin Only
                            if (role == UserRole.admin) ...[
                               Divider(color: Colors.white.withOpacity(0.2)),
                               _buildGlassListTile(context, 'User Management', Icons.admin_panel_settings, '/admin'),
                            ],
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.white70),
                              title: const Text('Logout', style: TextStyle(color: Colors.white70)),
                              onTap: () {
                                AuthService.instance.signOut();
                                Navigator.pop(context); // Close drawer
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserRole role) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
            ),
            child: CircleAvatar(
              radius: 26, 
              backgroundColor: Colors.white24,
              child: Icon(Icons.shield_moon, color: Colors.white.withOpacity(0.9), size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'DisasterLink', 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                  )
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    role.label.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlassListTile(BuildContext context, String title, IconData icon, String route) {
    final bool isActive = ModalRoute.of(context)?.settings.name == route;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white70),
        title: Text(
          title, 
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          )
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer first
          if (!isActive) {
             Navigator.pushReplacementNamed(context, route);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
