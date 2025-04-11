import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_service.dart'; // Ensure this file contains CloudinaryService
import 'package:logger/logger.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Initialize the logger
  final logger = Logger();

  Future<void> uploadImageAndStoreUrl(String userId, File imageFile) async {
    try {
      // Upload image to Cloudinary
      String? imageUrl = await _cloudinaryService.uploadImage(imageFile);

      if (imageUrl != null) {
        // Update Firestore with image URL
        await _db.collection('Users').doc(userId).update({
          'profileImageUrl': imageUrl,
        });
        logger.i("Image URL successfully stored in Firestore."); // Log info
      } else {
        logger.e("Image upload failed."); // Log error
      }
    } catch (e) {
      logger.e("Error uploading image: $e"); // Log error
    }
  }

  addMessage(String uid, String s) {}
}
