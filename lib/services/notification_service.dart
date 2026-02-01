import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Firebase Cloud Messaging and Notification persistence
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Initialize FCM settings, request permissions, and store token
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // 2. Get Token
    String? token;
    try {
      if (kIsWeb) {
        // VAPID key is optional for some setups but recommended. 
        // Using default getToken() behavior
        token = await _fcm.getToken(); 
      } else {
        token = await _fcm.getToken();
      }
      print('FCM Token: $token');
      // In a real app, send this token to your backend to target this device
    } catch (e) {
      print('Error getting FCM token: $e');
    }

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Optionally show a local dialog or snackbar here via a global key or stream
      }
      
      // Save received notification to Firestore for history
      _persistNotification(
        title: message.notification?.title ?? "New Message",
        body: message.notification?.body ?? "No details",
        type: 'received'
      );
    });

    _isInitialized = true;
  }

  /// Persist notification to Firestore for the UI list
  Future<void> _persistNotification({required String title, required String body, required String type}) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  /// Send a specific type of alert (Disaster, Volunteer, Donation)
  Future<void> sendTargetedAlert({
    required String title,
    required String body,
    required String category, // 'disaster', 'volunteer', 'donation'
  }) async {
    await _persistNotification(title: title, body: body, type: category);
  }

  /// Subscribe to specific topics (e.g. 'volunteers', 'donors')
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print('Subscribed to $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from specific topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      print('Unsubscribed from $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}

