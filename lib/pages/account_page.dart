import 'dart:io';
import 'package:chatapp/services/cloudinary_service.dart';
import 'package:chatapp/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

// Create logger instance
final Logger _logger = Logger('AccountPage');

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  final User currentUser = FirebaseAuth.instance.currentUser!;
  String username = '';
  String profileImageUrl = '';
  bool isImageLoading = false;
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController phoneController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(currentUser.uid)
              .get();

      // Debug: Log the entire document data
      _logger.info("User document data: ${userDoc.data()}");

      if (!userDoc.exists) {
        _logger.warning("User document does not exist!");
        setState(() {
          errorMessage = 'User profile not found. Please create one.';
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        _logger.warning("User document data is null!");
        setState(() {
          errorMessage = 'User data is empty.';
          isLoading = false;
        });
        return;
      }

      // Log individual fields to debug
      _logger.info("Username field: ${data['username']}");
      _logger.info("Profile image URL field: ${data['profileImageUrl']}");
      _logger.info("Phone field: ${data['phone']}");
      _logger.info("Full name field: ${data['fullName']}");
      _logger.info("Birth date field: ${data['birthDate']}");
      _logger.info("Gender field: ${data['gender']}");
      _logger.info("Bio field: ${data['bio']}");

      setState(() {
        username = data['username'] ?? 'No username';
        profileImageUrl = data['profileImageUrl'] ?? '';
        phoneController.text = data['phone'] ?? '';
        nameController.text = data['fullName'] ?? '';
        birthDateController.text = data['birthDate'] ?? '';
        genderController.text = data['gender'] ?? '';
        bioController.text = data['bio'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      _logger.severe("Error fetching user data: $e");
      setState(() {
        errorMessage = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  // Create profile if it doesn't exist
  Future<void> createUserProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .set({
            'username': currentUser.email?.split('@')[0] ?? 'User',
            'email': currentUser.email,
            'phone': '',
            'fullName': '',
            'birthDate': '',
            'gender': '',
            'bio': '',
            'profileImageUrl': '',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      fetchUserData();
    } catch (e) {
      _logger.severe("Error creating user profile: $e");
      setState(() {
        errorMessage = 'Error creating profile: $e';
      });
    }
  }

  Future<void> updateUserData(String field, String value) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .update({field: value});

      fetchUserData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$field updated successfully')));
      }
    } catch (e) {
      _logger.severe("Error updating field $field: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating $field: $e')));
      }
    }
  }

  Future<void> uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() {
      isImageLoading = true;
    });

    try {
      // Get file details
      final File imageFile = File(image.path);
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';

      // Log debug info
      _logger.info("Uploading image: ${image.path}");
      _logger.info("File size: ${await imageFile.length()} bytes");
      _logger.info("File name: $fileName");

      // Verify file exists
      if (!await imageFile.exists()) {
        throw Exception("Selected image file doesn't exist on device");
      }

      // Upload image using Cloudinary
      final cloudinaryService = CloudinaryService();
      final String? imageUrl = await cloudinaryService.uploadImage(imageFile);

      if (imageUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      _logger.info('Cloudinary Upload complete. Image URL: $imageUrl');

      // Save the image URL to Firestore
      final databaseService = DatabaseService();
      await databaseService.addMessage(
        currentUser.uid,
        'Profile image uploaded',
      );

      // Update Firestore user document with the new image URL
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .update({'profileImageUrl': imageUrl});

      // Refresh user data
      fetchUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      }
    } on FirebaseException catch (e) {
      _logger.severe(
        "Firebase error uploading image: ${e.code} - ${e.message}",
      );
      String errorMessage = 'Error uploading image';

      // Handle specific Firebase Storage errors
      if (e.code == 'object-not-found') {
        errorMessage =
            'Storage location not found. Check your Firebase configuration.';
      } else if (e.code == 'unauthorized') {
        errorMessage =
            'Not authorized to access storage. Check your Firebase rules.';
      } else if (e.code == 'canceled') {
        errorMessage = 'Upload canceled';
      } else {
        errorMessage = 'Upload error: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      _logger.severe("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      setState(() {
        isImageLoading = false;
      });
    }
  }

  void showEditDialog(
    String title,
    TextEditingController controller,
    String field,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $title"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                updateUserData(field, controller.text);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Account",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(30),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                ? _buildErrorState()
                : _buildAccountContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: createUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Create Profile"),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                _buildProfileImage(),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentUser.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: uploadProfileImage,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child:
                  profileImageUrl.isNotEmpty
                      ? Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                      )
                      : Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
            ),
          ),
          if (isImageLoading)
            const Positioned.fill(child: CircularProgressIndicator()),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Personal Information",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildInfoItem("Phone", phoneController, "phone"),
        _buildInfoItem("Full Name", nameController, "fullName"),
        _buildInfoItem("Birth Date", birthDateController, "birthDate"),
        _buildInfoItem("Gender", genderController, "gender"),
        _buildInfoItem("Bio", bioController, "bio"),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: fetchUserData,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh Data"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    TextEditingController controller,
    String field,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.text.isEmpty ? 'Not set' : controller.text,
                  style: TextStyle(
                    color:
                        controller.text.isEmpty
                            ? Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(128)
                            : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showEditDialog(label, controller, field),
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
