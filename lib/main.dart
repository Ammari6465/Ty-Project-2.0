import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load();
  
  String? firebaseError;
  
  // Initialize Firebase
  try {
    // On web, Firebase requires explicit FirebaseOptions. On Android/iOS,
    // google-services files supply configuration so options are not needed.
    if (kIsWeb) {
      final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAKhl_U_wtWQW7QrPAqHcKJ8aWghIAHKAo",
          authDomain: "disaster-link-ec682.firebaseapp.com",
          projectId: "disaster-link-ec682",
          storageBucket: "disaster-link-ec682.firebasestorage.app",
          messagingSenderId: "480593223354",
          appId: "1:480593223354:web:0b439feb35c27ea0696c83",
          measurementId: "G-RPCQQ333M6",
        ),
      );
      // ignore: avoid_print
      print('✅ Firebase (web) initialized: ${app.name}');
    } else {
      final app = await Firebase.initializeApp();
      // ignore: avoid_print
      print('✅ Firebase (mobile) initialized: ${app.name}');
    }
    // ignore: avoid_print
    print('   Total Firebase apps: ${Firebase.apps.length}');
    // ignore: avoid_print
    print('   Project ID: ${Firebase.apps.first.options.projectId}');
  } catch (e, st) {
    firebaseError = e.toString();
    // ignore: avoid_print
    print('❌ Firebase initialization FAILED:');
    // ignore: avoid_print
    print('   Error: $e');
    // ignore: avoid_print
    print('   Stack: $st');
  }
  
  // Show initialization error as a banner if failed
  if (firebaseError != null) {
    runApp(MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Initialization Error'),
          backgroundColor: Colors.red,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase initialization failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(firebaseError),
                const SizedBox(height: 16),
                const Text('Firebase Steps to fix:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('1. Verify google-services.json is in android/app/'),
                const Text('2. Run: flutter clean && flutter pub get'),
                const Text('3. Rebuild the app'),
              ],
            ),
          ),
        ),
      ),
    ));
    return;
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Oops — something went wrong.', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(details.exceptionAsString()),
            ],
          ),
        ),
      );

  runApp(const DisasterLinkApp());
}

// Entrypoint replaced to bootstrap the DisasterLink app scaffold and routing.

