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
import '../widgets/animated_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firebase not initialized yet')));
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email & 6+ char password required')));
      return;
    }
    try {
      setState(() => _loading = true);
      final user = await AuthService.instance.register(email, password);
      final uid = user?.uid;
      if (uid == null) {
        throw Exception('Registration failed: user session missing');
      }
      await FirestoreService.instance.ensureGuestProfile(uid, email: email);
      RoleService.instance.setRole(UserRole.guest);
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } on Exception catch (e) {
      // ignore: avoid_print
      print('Register error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: ${e.toString()}')));
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Register', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // drawer: const AppDrawer(), // Hide drawer on auth screens usually
      body: AnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                 return Transform.translate(
                   offset: Offset(0, 50 * (1 - value)),
                   child: Opacity(opacity: value, child: child),
                 );
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                       decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.1),
                               blurRadius: 20,
                               spreadRadius: 5,
                             )
                          ],
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (Firebase.apps.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2, valueColor: AlwaysStoppedAnimation(Colors.amber))),
                                  SizedBox(width:8),
                                  Text('Initializing services...', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          const Icon(Icons.person_add_alt_1, size: 50, color: Colors.white),
                          const SizedBox(height: 16),
                          const Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          const Text('Join the disaster response network', style: TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
                          const SizedBox(height: 32),
                          GlassmorphicTextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            label: 'Email',
                            hint: 'your.email@example.com',
                            prefixIcon: Icons.email_outlined,
                            labelColor: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          GlassmorphicTextField(
                            controller: _passwordController,
                            obscureText: true,
                            label: 'Password',
                             hint: '6+ characters',
                            prefixIcon: Icons.lock_outline,
                            labelColor: Colors.white,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                                shadowColor: AppTheme.successGreen.withOpacity(0.5),
                              ),
                              onPressed: _loading ? null : _register,
                              child: _loading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) 
                                : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text('Already have an account? Log in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

    );
  }
}
