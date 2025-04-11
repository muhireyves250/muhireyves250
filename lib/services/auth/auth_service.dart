import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instance of Firebase Auth & Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign user in
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Reference to the user document
      DocumentReference userDoc = _firestore
          .collection("Users")
          .doc(userCredential.user!.uid);

      // Check if the user document already exists
      DocumentSnapshot docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // If user does not exist, create new data
        await userDoc.set({
          'uid': userCredential.user!.uid,
          'email': email,
          'username': email.split('@')[0], // Default username
          'profileImageUrl': '', // Empty profile image URL
          'fullName': email.split('@')[0], // Default full name
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign up
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user info in Firestore
      await _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': email.split('@')[0], // Default username
        'profileImageUrl': '', // Empty profile image URL
        'fullName': email.split('@')[0], // Default full name
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Save user info
  Future<void> saveUserInfo(
    String username,
    String email, {
    String? fullName,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updateData = {'username': username, 'email': email};

      // Only add these fields if they're provided
      if (fullName != null) {
        updateData['fullName'] = fullName;
      }

      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      await _firestore
          .collection("Users")
          .doc(_auth.currentUser!.uid)
          .update(updateData);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Update profile image
  Future<void> updateProfileImage(String imageUrl) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection("Users").doc(currentUser.uid).update({
          'profileImageUrl': imageUrl,
        });
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }
}
