// Test script to verify attendance collection access
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/services/schedule_service.dart';
import 'lib/session_manager.dart';

Future<void> main() async {
  print('Testing attendance collection access...');

  try {
    // Initialize Firebase (would normally be done in main.dart)
    print('Initializing Firebase...');

    final scheduleService = ScheduleService();

    // Test getting user schedules from attendance collection
    print('Fetching user schedules from attendance collection...');
    final schedules = await scheduleService.getUserSchedules();

    print('Found ${schedules.length} schedules from attendance collection');

    for (var schedule in schedules) {
      print('Schedule ID: ${schedule.id}');
      print('Branch: ${schedule.branchName}');
      print('Start Date: ${schedule.startDate}');
      print('Assigned Employees: ${schedule.assignedEmployees}');
      print('---');
    }
  } catch (e) {
    print('Error testing attendance access: $e');
  }
}
