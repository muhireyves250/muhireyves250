import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notification settings
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Set up Firebase message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Get and store FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);
  }

  // Request notification permissions
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('Notification permissions granted');
    } else {
      log('Notification permissions denied');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('Users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    log('Got a message in foreground!');
    if (message.notification != null) {
      log('Message notification: ${message.notification?.title}');
      log('Message notification: ${message.notification?.body}');
    }
  }

  // Handle when app is opened from notification
  void _handleNotificationOpen(RemoteMessage message) {
    if (message.data['chatId'] != null) {
      // Implement navigation to specific chat
      log('Navigate to chat: ${message.data['chatId']}');
    }
  }

  // Send notification to specific user
  Future<void> sendNotification({
    required String receiverId,
    required String message,
    required String senderName,
    required String chatId,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverDoc =
          await _firestore.collection('Users').doc(receiverId).get();
      final receiverToken = receiverDoc.data()?['fcmToken'];

      if (receiverToken != null) {
        // Create notification document
        await _firestore.collection('notifications').add({
          'token': receiverToken,
          'title': '$senderName sent you a message',
          'body': message,
          'chatId': chatId,
          'timestamp': FieldValue.serverTimestamp(),
          'receiverId': receiverId,
          'senderId': _auth.currentUser?.uid,
        });
      }
    } catch (e) {
      log('Error sending notification: $e');
    }
  }
}

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling background message: ${message.messageId}');
}
