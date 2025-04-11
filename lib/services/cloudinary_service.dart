import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class CloudinaryService {
  final String cloudName = "dgrc9orud"; // Your Cloudinary Cloud Name
  final String uploadPreset = "yvesmuhire"; // Replace with your actual preset

  final logger = Logger(); // Initialize logger

  Future<String?> uploadImage(File imageFile) async {
    final url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    try {
      final request =
          http.MultipartRequest("POST", Uri.parse(url))
            ..fields['upload_preset'] = uploadPreset
            ..files.add(
              await http.MultipartFile.fromPath("file", imageFile.path),
            );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url']; // Return the image URL
      } else {
        logger.e("Cloudinary Upload Failed: ${jsonData['error']}"); // Log error
        return null;
      }
    } catch (e) {
      logger.e("Error uploading image: $e"); // Log error
      return null;
    }
  }
}
