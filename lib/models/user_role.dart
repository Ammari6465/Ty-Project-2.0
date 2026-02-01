enum UserRole {
  admin,
  ngo,
  volunteer,
  guest,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.ngo:
        return 'NGO';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.guest:
        return 'Guest';
    }
  }

  String get firestoreValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.ngo:
        return 'ngo';
      case UserRole.volunteer:
        return 'volunteer';
      case UserRole.guest:
        return 'guest';
    }
  }

  static UserRole? fromFirestoreValue(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'admin':
        return UserRole.admin;
      case 'ngo':
        return UserRole.ngo;
      case 'volunteer':
        return UserRole.volunteer;
      case 'guest':
        return UserRole.guest;
      default:
        return null;
    }
  }
}
