import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Helper class to set up UID mapping for users who already exist
class UidMappingHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates UID mapping for existing users
  static Future<void> createUidMapping({
    required String originalAuthUid,
    required String customUid,
  }) async {
    try {
      print('Creating UID mapping:');
      print('Original Auth UID: $originalAuthUid');
      print('Custom UID: $customUid');

      await _firestore.collection('uid_mapping').doc(originalAuthUid).set({
        'originalAuthUid': originalAuthUid,
        'customUid': customUid,
        'createdAt': DateTime.now(),
      });

      print('✅ UID mapping created successfully');
    } catch (e) {
      print('❌ Error creating UID mapping: $e');
      rethrow;
    }
  }

  /// Creates mapping for the user from your screenshots
  static Future<void> createMappingForSSM022() async {
    await createUidMapping(
      originalAuthUid: 'OA3FVK1zbcWo2exDVUwFpfBxzmz2',
      customUid: 'SSM022',
    );
  }

  /// Verifies if a UID mapping exists
  static Future<bool> checkUidMapping(String originalAuthUid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('uid_mapping').doc(originalAuthUid).get();

      if (doc.exists) {
        print('✅ UID mapping exists for: $originalAuthUid');
        print('Maps to custom UID: ${doc.get('customUid')}');
        return true;
      } else {
        print('❌ No UID mapping found for: $originalAuthUid');
        return false;
      }
    } catch (e) {
      print('Error checking UID mapping: $e');
      return false;
    }
  }

  /// Get current user's custom UID
  static Future<String?> getCurrentUserCustomUid() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        return null;
      }

      DocumentSnapshot doc =
          await _firestore.collection('uid_mapping').doc(currentUser.uid).get();

      if (doc.exists) {
        String customUid = doc.get('customUid');
        print('Current user custom UID: $customUid');
        return customUid;
      } else {
        print('No custom UID mapping found for current user');
        return null;
      }
    } catch (e) {
      print('Error getting current user custom UID: $e');
      return null;
    }
  }
}
