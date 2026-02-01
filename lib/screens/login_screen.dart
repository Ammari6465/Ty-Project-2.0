import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/role_service.dart';
import '../models/user_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  UserRole _selectedRole = UserRole.volunteer;

  Future<void> _login() async {
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firebase not initialized yet')));
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter email and password'),
        ),
      );
      return;
    }
    try {
      setState(() => _loading = true);
      // 1. Firebase Auth Login
      final user = await AuthService.instance.signIn(email, password);
      final uid = user?.uid;
      if (uid == null) {
        throw Exception('Login failed: user session missing');
      }

      // 2. Role Check (Non-blocking / Best Effort)
      UserRole finalRole = _selectedRole;
      try {
        // Pass email to fetchUserRole to look up in Roles/{email}
        UserRole? backendRole = await FirestoreService.instance.fetchUserRole(uid, email: email);
        
        if (backendRole == null) {
          // First time seeing this user in Firestore? Create profile.
          await FirestoreService.instance.ensureUserProfile(uid, _selectedRole, email: email);
          finalRole = _selectedRole;
        } else {
          // User exists. Respect backend role, but don't crash if mismatch.
          if (backendRole != _selectedRole) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Notice: Logged in as ${backendRole.label} (assigned by system)')),
            );
          }
          finalRole = backendRole;
        }
      } catch (e) {
        // Firestore failed (offline, permission, etc.)
        // Fallback: Allow login with selected role so user isn't locked out.
        print('Firestore role check failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline mode: Using selected role')),
        );
        finalRole = _selectedRole;
      }

      RoleService.instance.setRole(finalRole);
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } on Exception catch (e) {
      // ignore: avoid_print
      print('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DisasterLink — Login')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (Firebase.apps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)),
                          SizedBox(width:8),
                          Text('Initializing services...'),
                        ],
                      ),
                    ),
                  const Text('Welcome to DisasterLink',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Login Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                      DropdownMenuItem(value: UserRole.ngo, child: Text('NGO')),
                      DropdownMenuItem(value: UserRole.volunteer, child: Text('Volunteer')),
                    ],
                    onChanged: _loading
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() => _selectedRole = v);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text('Forgot?'),
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    if (_selectedRole != UserRole.guest) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Only Guest accounts can be registered here. Admin/NGO/Volunteer are created by admin (backend).'),
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pushNamed(context, '/register');
                                  },
                            child: const Text('Register'),
                          ),
                        ],
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
}
