import 'package:flutter/material.dart';
import 'lib/admin_home_page.dart';

void main() {
  runApp(TestDrillDownApp());
}

class TestDrillDownApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drill-Down Navigation Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TestEmployeeAttendancePage(),
    );
  }
}

class TestEmployeeAttendancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('🚀 Testing drill-down navigation for EmployeeAttendancePage...');

    return Scaffold(
      appBar: AppBar(
        title: Text('Test Drill-Down Navigation'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Drill-Down Navigation Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Level 1: Click employee card → Shows dates with currentDate',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Level 2: Click date card → Shows attendance details',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeAttendancePage(),
                  ),
                );
              },
              child: Text('Open Employee Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
