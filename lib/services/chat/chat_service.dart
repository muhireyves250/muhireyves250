import 'dart:io';
import 'package:chatapp/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notification_service.dart';
import '../cloudinary_service.dart';

class ChatService {
  // Get instance of Firestore & Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Add a new method to fetch user profile
  Future<Map<String, dynamic>> fetchUserProfile(String userID) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection("Users").doc(userID).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return {
          'uid': userDoc.id,
          'email': data['email'] ?? '',
          'fullName': data['fullName'] ?? 'No Name',
          'username': data['username'] ?? 'User',
          'profileImageUrl': data['profileImageUrl'] ?? '',
          'phone': data['phone'] ?? '',
          'bio': data['bio'] ?? '',
        };
      }
      return {
        'uid': userID,
        'email': '',
        'fullName': 'Unknown User',
        'username': 'User',
        'profileImageUrl': '',
        'phone': '',
        'bio': '',
      };
    } catch (e) {
      return {
        'uid': userID,
        'email': '',
        'fullName': 'Error loading user',
        'username': 'Error',
        'profileImageUrl': '',
        'phone': '',
        'bio': '',
      };
    }
  }

  // Modify getUsersStream to ensure complete profile data
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return {
          'id': doc.id,
          'uid': doc.id,
          'email': user['email'] ?? '',
          'fullName': user['fullName'] ?? 'No Name',
          'username': user['username'] ?? 'User',
          'profileImageUrl': user['profileImageUrl'] ?? '',
          'phone': user['phone'] ?? '',
          'bio': user['bio'] ?? '',
          'lastSeen': user['lastSeen'],
          'isOnline': user['isOnline'] ?? false,
        };
      }).toList();
    });
  }

  // Send message
  Future<void> sendMessage(String receiverID, String message) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception("No user logged in");
    }

    final String currentUserID = currentUser.uid;
    final String currentUserEmail = currentUser.email!;
    final Timestamp timestamp = Timestamp.now();

    // Create new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    // Construct chat room ID
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Add message to database
    await _firestore
        .collection("chat_room")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());

    // After saving the message, send notification
    final senderDoc =
        await _firestore.collection("Users").doc(currentUserID).get();
    final senderName = senderDoc.data()?['username'] ?? currentUserEmail;

    await _notificationService.sendNotification(
      receiverId: receiverID,
      message: message,
      senderName: senderName,
      chatId: chatRoomID,
    );
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    // Construct a chatroom ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_room")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // Send image message
  Future<void> sendImageMessage(String receiverID, File imageFile) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("No user logged in");

      // Upload image to Cloudinary
      String? imageUrl = await _cloudinaryService.uploadImage(imageFile);
      if (imageUrl == null) throw Exception("Failed to upload image");

      final String currentUserID = currentUser.uid;
      final String currentUserEmail = currentUser.email!;
      final Timestamp timestamp = Timestamp.now();

      // Create new message with image
      Message newMessage = Message(
        senderID: currentUserID,
        senderEmail: currentUserEmail,
        receiverID: receiverID,
        message: '', // Empty message for image type
        timestamp: timestamp,
        type: 'image',
        imageUrl: imageUrl,
      );

      // Construct chat room ID
      List<String> ids = [currentUserID, receiverID];
      ids.sort();
      String chatRoomID = ids.join('_');

      // Add message to database
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomID)
          .collection('messages')
          .add(newMessage.toMap());

      // Get sender's name for notification
      DocumentSnapshot senderDoc =
          await _firestore.collection('Users').doc(currentUserID).get();

      String senderName = '';
      if (senderDoc.exists) {
        final data = senderDoc.data() as Map<String, dynamic>;
        senderName = data['fullName'] ?? data['username'] ?? 'Someone';
      }

      // Send notification with correct parameters
      await _notificationService.sendNotification(
        receiverId: receiverID,
        message: "Sent you a photo",
        senderName: senderName,
        chatId: chatRoomID,
      );
    } catch (e) {
      throw Exception("Error sending image: $e");
    }
  }
}
