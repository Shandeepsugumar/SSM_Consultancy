import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final List<String> assignedEmployees;
  final String branchName;
  final DateTime endDate;
  final String endTime;
  final int numberOfWorkers;
  final DateTime startDate;
  final String startTime;
  final String status;
  final Timestamp timestamp;
  final String totalHours;

  ScheduleModel({
    required this.id,
    required this.assignedEmployees,
    required this.branchName,
    required this.endDate,
    required this.endTime,
    required this.numberOfWorkers,
    required this.startDate,
    required this.startTime,
    required this.status,
    required this.timestamp,
    required this.totalHours,
  });

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Debug logging to see actual data from Firestore
    print('Parsing document ${doc.id}:');
    print('Raw data: $data');
    print(
        'startDate from Firestore: ${data['startDate']} (type: ${data['startDate'].runtimeType})');
    print(
        'endDate from Firestore: ${data['endDate']} (type: ${data['endDate'].runtimeType})');
    print('assignedEmployees: ${data['assignedEmployees']}');
    print('branchName: ${data['branchName']}');
    print('status: ${data['status']}');

    return ScheduleModel(
      id: doc.id,
      assignedEmployees: List<String>.from(data['assignedEmployees'] ?? []),
      branchName: data['branchName'] ?? '',
      endDate: _parseDate(data['endDate']) ??
          DateTime(1900, 1, 1), // Obvious fallback
      endTime: data['endTime'] ?? '',
      numberOfWorkers: data['numberOfWorkers'] ?? 0,
      startDate: _parseDate(data['startDate']) ??
          DateTime(1900, 1, 1), // Obvious fallback
      startTime: data['startTime'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      totalHours: data['totalHours'] ?? '0',
    );
  }
  static DateTime? _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      // Try standard parsing first
      DateTime? parsed = DateTime.tryParse(date);
      if (parsed != null) {
        return parsed;
      }

      // Try parsing format like "2025-4-17"
      try {
        final parts = date.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } catch (e) {
        print('Error parsing date: $date, error: $e');
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'assignedEmployees': assignedEmployees,
      'branchName': branchName,
      'endDate': Timestamp.fromDate(endDate),
      'endTime': endTime,
      'numberOfWorkers': numberOfWorkers,
      'startDate': Timestamp.fromDate(startDate),
      'startTime': startTime,
      'status': status,
      'timestamp': timestamp,
      'totalHours': totalHours,
    };
  }

  bool isScheduledForDate(DateTime date) {
    // Normalize dates to compare only date parts (ignore time)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEndDate =
        DateTime(endDate.year, endDate.month, endDate.day);

    // Check if the date falls within the schedule period (inclusive)
    return normalizedDate.isAtSameMomentAs(normalizedStartDate) ||
        normalizedDate.isAtSameMomentAs(normalizedEndDate) ||
        (normalizedDate.isAfter(normalizedStartDate) &&
            normalizedDate.isBefore(normalizedEndDate));
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool isExpired() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedEndDate =
        DateTime(endDate.year, endDate.month, endDate.day);

    // Work is expired if status is "not done" and end date has passed
    return status.toLowerCase() == "not done" &&
        normalizedToday.isAfter(normalizedEndDate);
  }

  String getDisplayStatus() {
    if (isExpired()) {
      return "EXPIRED";
    }
    return status.toUpperCase();
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? role;
  final String? department;
  final String? eid; // Employee ID field

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.role,
    this.department,
    this.eid,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      role: data['role'],
      department: data['department'],
      eid: data['Eid'], // Get Eid field from document
    );
  }
}
