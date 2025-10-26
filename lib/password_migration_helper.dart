import 'package:cloud_firestore/cloud_firestore.dart';
import 'binary_password_helper.dart';

/// Helper class to convert existing plain text passwords to binary format
class PasswordMigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Convert a specific user's password to binary format
  static Future<void> convertUserPasswordToBinary({
    required String userId,
    required String plainPassword,
  }) async {
    try {
      print('Converting password for user: $userId');

      // Convert password to binary
      String binaryPassword =
          BinaryPasswordHelper.generateBinaryPassword(plainPassword);
      print('Original password: $plainPassword');
      print('Binary password: $binaryPassword');

      // Update user document with binary password
      await _firestore.collection('users').doc(userId).update({
        'password': binaryPassword,
        'passwordUpdated': DateTime.now(),
      });

      print('✅ Password converted successfully for user: $userId');
    } catch (e) {
      print('❌ Error converting password for user $userId: $e');
      rethrow;
    }
  }

  /// Convert password for SSM022 user based on your screenshot
  static Future<void> convertSSM022Password() async {
    // Based on your screenshot, the user SSM022 exists
    // You'll need to provide the actual plain text password that corresponds
    // to the hash "4ee7ffea047070f4f7faa5b54ef0ee8bbba2d0f644c2c6e5b58e" in your database

    // Example - replace with actual password:
    await convertUserPasswordToBinary(
      userId: 'SSM022',
      plainPassword: 'actualPasswordHere', // Replace with real password
    );
  }

  /// Convert all users' passwords from plain text to binary
  /// WARNING: Use this only if you know all current passwords are in plain text
  static Future<void> convertAllPasswordsToBinary() async {
    try {
      print('Starting bulk password conversion...');

      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      for (DocumentSnapshot userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String currentPassword = userData['password'] ?? '';

        if (currentPassword.isNotEmpty) {
          // Check if password is already binary (contains only 0s and 1s)
          bool isAlreadyBinary = RegExp(r'^[01]+$').hasMatch(currentPassword);

          if (!isAlreadyBinary) {
            print('Converting password for user: ${userDoc.id}');
            String binaryPassword =
                BinaryPasswordHelper.generateBinaryPassword(currentPassword);

            await _firestore.collection('users').doc(userDoc.id).update({
              'password': binaryPassword,
              'passwordUpdated': DateTime.now(),
              'originalPasswordHash': currentPassword, // Keep backup
            });

            print('✅ Converted password for user: ${userDoc.id}');
          } else {
            print(
                '⏩ Password already in binary format for user: ${userDoc.id}');
          }
        }
      }

      print('✅ Bulk password conversion completed');
    } catch (e) {
      print('❌ Error during bulk password conversion: $e');
      rethrow;
    }
  }

  /// Test password conversion for a specific user
  static Future<void> testPasswordConversion(
      String userId, String testPassword) async {
    try {
      print('Testing password conversion for user: $userId');

      // Convert to binary
      String binaryPassword =
          BinaryPasswordHelper.generateBinaryPassword(testPassword);
      print('Test password: $testPassword');
      print('Binary representation: $binaryPassword');

      // Test verification
      bool verificationResult =
          BinaryPasswordHelper.verifyPassword(testPassword, binaryPassword);
      print('Verification test: $verificationResult');

      if (verificationResult) {
        print('✅ Password conversion test passed');
      } else {
        print('❌ Password conversion test failed');
      }
    } catch (e) {
      print('Error testing password conversion: $e');
    }
  }

  /// Check current password format for a user
  static Future<void> checkUserPasswordFormat(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String password = userData['password'] ?? '';

        bool isBinary = RegExp(r'^[01]+$').hasMatch(password);

        print('User: $userId');
        print('Password: $password');
        print('Is Binary: $isBinary');
        print('Length: ${password.length}');

        if (isBinary && password.length % 8 == 0) {
          print('✅ Password is in correct binary format');
          // Try to convert back to see original
          try {
            String original = BinaryPasswordHelper.convertFromBinary(password);
            print('Original password would be: $original');
          } catch (e) {
            print('Could not convert back to original: $e');
          }
        } else {
          print('❌ Password needs conversion to binary format');
        }
      } else {
        print('User not found: $userId');
      }
    } catch (e) {
      print('Error checking password format: $e');
    }
  }
}
