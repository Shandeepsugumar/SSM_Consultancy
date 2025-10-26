import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'location_channel',
      initialNotificationTitle: 'Location Tracking',
      initialNotificationContent: 'Tracking your location in background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Initialize Firebase for background service
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase already initialized or error: $e');
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  Timer.periodic(const Duration(minutes: 5), (timer) async {
    await updateLocationToFirestore();
  });
  // Also send location immediately
  await updateLocationToFirestore();
}

Future<void> updateLocationToFirestore() async {
  try {
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // Import SessionManager to get custom UID
    // Note: We need to get the custom UID from SharedPreferences since SessionManager might not be available in background
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? customUid =
        prefs.getString('userUid'); // Get custom UID from shared preferences

    if (customUid == null) {
      print(
          'No custom UID found in shared preferences, skipping location update');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied.');
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Get user data from the users collection using custom UID
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(customUid)
        .get();

    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    String name = userData?['name'] ?? 'Unknown User';
    String email = userData?['email'] ?? '';
    String mobile = userData?['mobile'] ?? '';
    String eid =
        userData?['Eid'] ?? customUid; // Get Eid field to use as document name

    // Ensure UID mapping exists for Firebase Auth (if available)
    try {
      // Try to get Firebase Auth user (might not be available in background)
      // This is a best-effort attempt to ensure mapping exists
      await FirebaseFirestore.instance
          .collection('uid_mapping')
          .doc('background_service')
          .set({
        'customUid': customUid,
        'service': 'background_location',
        'lastUpdate': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Note: Background service UID mapping not critical: $e');
    }

    // Store in live_locations collection with custom UID as document name
    await FirebaseFirestore.instance
        .collection('live_locations')
        .doc(customUid) // Use custom UID as document name
        .set({
      'employeeId': customUid, // Store the custom employee ID
      'Eid': eid, // Store the Eid field
      'name': name,
      'email': email,
      'mobile': mobile,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'lastUpdate': DateTime.now().toIso8601String(),
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'speed': position.speed,
      'status':
          'background', // Indicates this was updated from background service
    }, SetOptions(merge: true));

    print(
        '✅ Background location updated successfully for Employee ID: $customUid');
    print('👤 Name: $name');
    print(
        '📍 Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    print('🔗 Document ID in live_locations: $customUid');
  } catch (e) {
    print('Error sending background location: $e');
  }
}
