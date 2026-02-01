import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:ui';
import '../widgets/app_drawer.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/role_service.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_textfield.dart';

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
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.purpleGradient),
        child: Stack(
          children: [
            // Animated background shapes
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App title
                      const Text(
                        'DisasterLink',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Respond. Relief. Recovery.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Glassmorphic card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Role selector
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: DropdownButton<UserRole>(
                                    value: _selectedRole,
                                    items: const [
                                      DropdownMenuItem(
                                        value: UserRole.admin,
                                        child: Text('👨‍💼 Admin'),
                                      ),
                                      DropdownMenuItem(
                                        value: UserRole.ngo,
                                        child: Text('🏢 NGO'),
                                      ),
                                      DropdownMenuItem(
                                        value: UserRole.volunteer,
                                        child: Text('🤝 Volunteer'),
                                      ),
                                    ],
                                    onChanged: _loading
                                        ? null
                                        : (v) {
                                            if (v != null) {
                                              setState(() => _selectedRole = v);
                                            }
                                          },
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Email field
                                GlassmorphicTextField(
                                  label: 'Email',
                                  hint: 'Enter your email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                // Password field
                                GlassmorphicTextField(
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  controller: _passwordController,
                                  obscureText: true,
                                ),
                                const SizedBox(height: 28),
                                // Sign in button
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryPurple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                    onPressed: _loading ? null : _login,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            'Sign in',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Footer links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot your password?',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Text('•', style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    if (_selectedRole != UserRole.guest) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Only Guest accounts can be registered here.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pushNamed(context, '/register');
                                  },
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
