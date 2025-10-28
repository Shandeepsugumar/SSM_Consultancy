import 'package:flutter/material.dart';
import 'lib/admin_home_page.dart';

void main() {
  print('🔥 Testing EmployeeAttendancePage with our fixed implementation...');
  
  runApp(MaterialApp(
    title: 'Admin Attendance Test',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: Scaffold(
      appBar: AppBar(title: Text('Test Admin Attendance')),
      body: EmployeeAttendancePage(),
    ),
  ));
}