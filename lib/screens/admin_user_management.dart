import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/firestore_service.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_list_tile.dart';
import '../widgets/modern_stat_card.dart';

import '../widgets/glassmorphic_textfield.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.volunteer;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add New User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GlassmorphicTextField(
                    controller: nameController,
                    label: 'Full Name',
                    hint: 'Enter full name',
                    labelColor: AppTheme.textDark,
                  ),
                  const SizedBox(height: 12),
                  GlassmorphicTextField(
                    controller: emailController,
                    label: 'Email Address',
                    hint: 'Enter email address',
                    labelColor: AppTheme.textDark,
                  ),
                  const SizedBox(height: 12),
                  GlassmorphicTextField(
                    controller: passwordController,
                    label: 'Password',
                    hint: 'Enter password',
                    obscureText: true,
                    labelColor: AppTheme.textDark,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBrand.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryBrand.withOpacity(0.2)),
                    ),
                    child: DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: AppTheme.textDark),
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        labelStyle: TextStyle(color: AppTheme.textLight),
                        border: InputBorder.none,
                      ),
                      items: UserRole.values
                          .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedRole = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.textLight)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final email = emailController.text.trim();
                          final name = nameController.text.trim();
                          final password = passwordController.text.trim();

                          if (email.isEmpty || name.isEmpty || password.isEmpty) {
                            return;
                          }

                          try {
                            await FirestoreService.instance.addNewUser(
                                email: email, password: password, fullName: name, role: selectedRole);
                            if (mounted) Navigator.pop(ctx);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: const Text('Add User'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  void _showEditRoleDialog(String docId, String email, UserRole currentRole) {
    UserRole selectedRole = currentRole;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Role',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBrand.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryBrand.withOpacity(0.2)),
                  ),
                  child: DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: AppTheme.textDark),
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      labelStyle: TextStyle(color: AppTheme.textLight),
                      border: InputBorder.none,
                    ),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => selectedRole = v);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textLight)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await FirestoreService.instance.updateUserRole(docId, selectedRole);
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String docId, String email) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete User?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete user $email? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: AppTheme.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await FirestoreService.instance.deleteUser(docId);
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Delete'),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      drawer: const AppDrawer(),
      backgroundColor: AppTheme.surfaceLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: AppTheme.primaryBrand,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add User', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.instance.streamAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: AppTheme.errorRed)),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            // Stats
            final total = docs.length;
            final volunteers = docs.where((d) => (d.data()['Role'] ?? d.data()['role']) == 'volunteer').length;
            final ngos = docs.where((d) => (d.data()['Role'] ?? d.data()['role']) == 'ngo').length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: ModernStatCard(
                              label: 'Total Users',
                              value: '$total',
                              icon: Icons.people,
                              color: AppTheme.primaryBrand)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: ModernStatCard(
                              label: 'Volunteers',
                              value: '$volunteers',
                              icon: Icons.volunteer_activism,
                              color: AppTheme.successGreen)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: ModernStatCard(
                              label: 'NGOs',
                              value: '$ngos',
                              icon: Icons.business,
                              color: AppTheme.accentBrand)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final email = data['Email'] as String? ?? 'No Email';
                      final roleStr = (data['Role'] ?? data['role']) as String?;
                      final role = UserRoleX.fromFirestoreValue(roleStr) ?? UserRole.guest;

                      Color roleColor = _getRoleColor(role);

                      return GlassListTile(
                        backgroundColor: Colors.white,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: roleColor.withOpacity(0.4)),
                          ),
                          child: Icon(_getRoleIcon(role), color: roleColor, size: 20),
                        ),
                        title: Text(
                          email,
                          style: const TextStyle(
                            color: AppTheme.textDark, 
                            fontWeight: FontWeight.w600
                          ),
                        ),
                        subtitle: Text(
                          'Role: ${role.label}',
                          style: const TextStyle(color: AppTheme.textLight),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppTheme.textLight),
                          color: Colors.white,
                          elevation: 3,
                          onSelected: (v) {
                            if (v == 'edit') _showEditRoleDialog(doc.id, email, role);
                            if (v == 'delete') _confirmDelete(doc.id, email);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit, size: 18, color: AppTheme.textDark),
                                  SizedBox(width: 8),
                                  Text('Change Role', style: TextStyle(color: AppTheme.textDark))
                                ])),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete, color: AppTheme.errorRed, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: AppTheme.errorRed))
                                ])),
                          ],
                        ),
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return AppTheme.errorRed;
      case UserRole.ngo: return AppTheme.accentBrand;
      case UserRole.volunteer: return AppTheme.successGreen;
      case UserRole.guest: return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin: return Icons.admin_panel_settings;
      case UserRole.ngo: return Icons.business;
      case UserRole.volunteer: return Icons.volunteer_activism;
      case UserRole.guest: return Icons.person_outline;
    }
  }
}
