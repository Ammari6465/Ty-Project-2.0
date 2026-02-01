import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/role_service.dart';

class RoleGate extends StatelessWidget {
  final Set<UserRole> allowed;
  final Widget child;

  const RoleGate({super.key, required this.allowed, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserRole>(
      valueListenable: RoleService.instance.role,
      builder: (context, role, _) {
        if (allowed.contains(role)) return child;
        return Scaffold(
          appBar: AppBar(title: const Text('Access denied')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 56),
                    const SizedBox(height: 12),
                    Text(
                      'You do not have permission to open this page.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current role: ${role.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false),
                      child: const Text('Go to Dashboard'),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
