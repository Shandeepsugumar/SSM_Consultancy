// main.dart (including SplashScreen)
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginpage.dart';
import 'background_location_service.dart';

// Global list for available cameras.
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  await Firebase.initializeApp();
  // Wait a moment for Firebase to fully initialize
  await Future.delayed(Duration(milliseconds: 500));
  // Temporarily disable background service to prevent crashes
  // await initializeService();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    startTracking(); // Start tracking location, if needed.

    // Navigate to the appropriate page after a delay.
    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  // Example function for tracking location (ensure proper permissions elsewhere).
  Future<void> startTracking() async {
    // Wait for authentication to ensure a valid user session.
    await FirebaseAuth.instance.authStateChanges().first;
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Your location tracking logic here (e.g., using geolocator)...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 250, height: 150),
            const SizedBox(height: 20),
            const Text('Powered by SSM',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
