import 'package:flutter/foundation.dart';

import '../models/user_role.dart';

class RoleService {
  RoleService._();
  static final RoleService instance = RoleService._();

  final ValueNotifier<UserRole> role = ValueNotifier<UserRole>(UserRole.guest);

  UserRole get currentRole => role.value;

  void setRole(UserRole newRole) {
    if (role.value == newRole) return;
    role.value = newRole;
  }

  static bool canAccessRoute(UserRole role, String routeName) {
    switch (routeName) {
      case '/dashboard':
        return true;
      case '/volunteer':
      case '/resources':
      case '/notifications':
      case '/analytics':
      case '/ai':
        // For demo purposes, allow Guest to view UI
        return true; 
      case '/admin':
        // For demo/dev purposes, allow access to admin panel
        return true;
      //  return role == UserRole.admin || role == UserRole.volunteer;
      default:
        return true;
    }
  }
}
