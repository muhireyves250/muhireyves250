import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final logger = Logger();

  Future<String?> uploadImage(File imageFile) async {
    try {
      logger.i('Starting image upload to Firebase Storage');

      // Create unique file name
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';

      // Create storage reference
      Reference ref = _storage.ref().child('chat_images/$fileName');

      // Upload file
      await ref.putFile(imageFile);

      // Get download URL
      String downloadUrl = await ref.getDownloadURL();

      logger.i('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading to Firebase Storage: $e');
      return null;
    }
  }
}
