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
        return role == UserRole.admin || role == UserRole.volunteer;
      case '/resources':
        return role == UserRole.admin || role == UserRole.volunteer || role == UserRole.ngo;
      case '/notifications':
        return role == UserRole.admin || role == UserRole.volunteer || role == UserRole.ngo;
      case '/ai':
        return role == UserRole.admin;
      case '/analytics':
        return role == UserRole.admin || role == UserRole.ngo;
      default:
        return true;
    }
  }
}
