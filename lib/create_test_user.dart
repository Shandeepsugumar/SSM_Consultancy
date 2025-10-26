import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to create test users
/// Call this once to create test users in your Firebase project
class TestUserCreator {
  static Future<void> createTestUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('Creating test user: $email');

      // Create Firebase Auth user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Create Firestore user document
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "email": email,
          "name": name,
          "createdAt": DateTime.now(),
          "qualification": "Test User",
          "experience": "0 years",
          "mobile": "0000000000",
          "address": "Test Address",
          "district": "Test District",
          "state": "Test State",
          "pincode": "000000",
        });

        print('Test user created successfully: ${user.uid}');
        print('Email: $email');
        print('Name: $name');

        // Sign out after creating
        await FirebaseAuth.instance.signOut();
        print('Signed out test user');
      }
    } catch (e) {
      print('Error creating test user: $e');
      rethrow;
    }
  }

  /// Create some common test users
  static Future<void> createCommonTestUsers() async {
    List<Map<String, String>> testUsers = [
      {
        'email': 'abc@gmail.com',
        'password': 'password123',
        'name': 'ABC User',
      },
      {
        'email': 'test@gmail.com',
        'password': 'password123',
        'name': 'Test User',
      },
      {
        'email': 'demo@gmail.com',
        'password': 'password123',
        'name': 'Demo User',
      },
    ];

    for (var userData in testUsers) {
      try {
        await createTestUser(
          email: userData['email']!,
          password: userData['password']!,
          name: userData['name']!,
        );
        print('✅ Created: ${userData['email']}');
      } catch (e) {
        print('❌ Failed to create ${userData['email']}: $e');
      }
    }
  }
}
