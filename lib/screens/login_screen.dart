import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:io';
import '../widgets/app_drawer.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/role_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_textfield.dart';
import '../widgets/animated_background.dart'; // Import AnimatedBackground

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

  Future<bool> _hasInternet() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<User?> _signInWithRetry(String email, String password) async {
    const maxAttempts = 2;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await AuthService.instance.signIn(email, password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'network-request-failed' && attempt < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 800));
          continue;
        }
        rethrow;
      }
    }
    return null;
  }

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
      final online = await _hasInternet();
      if (!online) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection. Please connect and try again.')),
        );
        return;
      }
      // 1. Firebase Auth Login
      final user = await _signInWithRetry(email, password);
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
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';
      switch (e.code) {
        case 'network-request-failed':
          message = 'Network error. Check your connection or disable VPN and try again.';
          break;
        case 'user-not-found':
          message = 'No account found for this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please wait and try again.';
          break;
      }
      // ignore: avoid_print
      print('Login error (${e.code}): ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } on Exception catch (e) {
      // ignore: avoid_print
      print('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
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
      body: AnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.fastOutSlowIn,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App title
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBrand.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(Icons.health_and_safety, size: 64, color: AppTheme.primaryBrand),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'DisasterLink',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBrand,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Respond. Relief. Recovery.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
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
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                               BoxShadow(
                                 color: AppTheme.primaryBrand.withOpacity(0.1),
                                 blurRadius: 20,
                                 spreadRadius: 5,
                               )
                            ],
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
                                  labelColor: AppTheme.textDark,
                                  prefixIcon: Icons.email,
                                ),
                                const SizedBox(height: 16),
                                // Password field
                                GlassmorphicTextField(
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  controller: _passwordController,
                                  obscureText: true,
                                  labelColor: AppTheme.textDark,
                                  prefixIcon: Icons.lock,
                              ),
                              const SizedBox(height: 28),
                              // Sign in button
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBrand,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: AppTheme.primaryBrand.withOpacity(0.5),
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
                              color: AppTheme.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Text('•', style: TextStyle(color: AppTheme.textLight)),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.pushNamed(context, '/register');
                                },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppTheme.primaryBrand,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

}
