import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionManager {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserUid = 'userUid';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserName = 'userName';
  static const String _keyUserData = 'userData';

  // Cache user data in memory to avoid repeated Firestore calls
  static Map<String, dynamic>? _cachedUserData;
  static String? _cachedUserUid;

  static Future<void> saveUserSession({
    required String customUid,
    required String email,
    required String name,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserUid, customUid);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserName, name);
      print('Session saved for user: $name (UID: $customUid)');
    } catch (e) {
      print('Error saving user session: $e');
    }
  }

  static Future<bool> isUserLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      String? uid = prefs.getString(_keyUserUid);
      return isLoggedIn && uid != null && uid.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  static Future<String?> getCurrentUserUid() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserUid);
    } catch (e) {
      print('Error getting current user UID: $e');
      return null;
    }
  }

  static Future<void> initializeFromFirebaseAuth() async {
    try {
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        print('Firebase user found: ${firebaseUser.uid}');
        String customUid = firebaseUser.uid;

        try {
          DocumentSnapshot mappingDoc = await FirebaseFirestore.instance
              .collection("uid_mapping")
              .doc(firebaseUser.uid)
              .get();

          if (mappingDoc.exists) {
            Map<String, dynamic> mappingData =
                mappingDoc.data() as Map<String, dynamic>;
            customUid = mappingData['customUid'] ?? firebaseUser.uid;
            print('Found custom UID: $customUid');
          }
        } catch (e) {
          print('Error fetching UID mapping: $e');
        }

        await saveUserSession(
          customUid: customUid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? 'User',
        );
      } else {
        print('No Firebase user found');
      }
    } catch (e) {
      print('Error initializing session from Firebase Auth: $e');
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      String? customUid = await getCurrentUserUid();
      if (customUid == null) {
        print('No user UID found in session');
        return null;
      }

      // Return cached data if available for the same user
      if (_cachedUserUid == customUid && _cachedUserData != null) {
        print('Returning cached user data for UID: $customUid');
        return _cachedUserData;
      }

      print('Fetching fresh user data for UID: $customUid');
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(customUid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Cache the data
        _cachedUserData = userData;
        _cachedUserUid = customUid;

        print('User data cached successfully');
        return userData;
      } else {
        print('User document not found for UID: $customUid');
        return null;
      }
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  static Future<void> clearUserSession() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserUid);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserName);

      // Clear cached data
      _cachedUserData = null;
      _cachedUserUid = null;

      print('User session and cache cleared successfully');
    } catch (e) {
      print('Error clearing user session: $e');
    }
  }

  // Method to refresh cached data
  static Future<void> refreshUserData() async {
    _cachedUserData = null;
    _cachedUserUid = null;
    await getCurrentUserData();
  }

  // Method to get user session data in the format expected by main.dart
  static Future<Map<String, String?>> getUserSession() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (!isLoggedIn) {
        return {'customUid': null, 'email': null, 'name': null};
      }

      String? customUid = prefs.getString(_keyUserUid);
      String? email = prefs.getString(_keyUserEmail);
      String? name = prefs.getString(_keyUserName);

      return {
        'customUid': customUid,
        'email': email,
        'name': name,
      };
    } catch (e) {
      print('Error getting user session: $e');
      return {'customUid': null, 'email': null, 'name': null};
    }
  }
}
