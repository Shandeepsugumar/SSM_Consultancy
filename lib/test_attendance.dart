import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin_attendance_simple.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Attendance',
      home: SimpleAttendancePage(),
    );
  }
}
