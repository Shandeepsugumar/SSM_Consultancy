import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';

class AdminComprehensiveAttendanceScreen extends StatefulWidget {
  @override
  _AdminComprehensiveAttendanceScreenState createState() =>
      _AdminComprehensiveAttendanceScreenState();
}

class _AdminComprehensiveAttendanceScreenState
    extends State<AdminComprehensiveAttendanceScreen> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllEmployeesWithAttendance();
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmployees() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = List.from(_employees);
      } else {
        _filteredEmployees = _employees
            .where((employee) =>
                employee['name'].toLowerCase().contains(query) ||
                employee['eid'].toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadAllEmployeesWithAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading all employees with attendance data...');

      // First, get all attendance documents to see what document names exist
      QuerySnapshot attendanceSnapshot =
          await FirebaseFirestore.instance.collection('attendance').get();

      print('Found ${attendanceSnapshot.docs.length} attendance documents');
      print(
          'Attendance document IDs: ${attendanceSnapshot.docs.map((doc) => doc.id).toList()}');

      // Get all users from the users collection
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      print('Found ${usersSnapshot.docs.length} users in the database');
      print('User UIDs: ${usersSnapshot.docs.map((doc) => doc.id).toList()}');

      List<Map<String, dynamic>> employeeList = [];

      // Process each attendance document
      for (QueryDocumentSnapshot attendanceDoc in attendanceSnapshot.docs) {
        String attendanceDocId = attendanceDoc.id;
        print('Processing attendance document: $attendanceDocId');

        try {
          // Load attendance records for this document
          Map<String, dynamic> attendanceData =
              await _loadEmployeeAttendanceRecordsWithEid(attendanceDocId);

          if (attendanceData['records'].isEmpty) {
            print('No attendance records found for document: $attendanceDocId');
            continue; // Skip if no attendance records
          }

          // Extract name and Eid from the first attendance record
          String name = attendanceData['name']?.toString() ?? 'Unknown';
          String eid = attendanceData['eid']?.toString() ?? 'N/A';

          print(
              'Processing employee: $name (EID: $eid) from document: $attendanceDocId');

          // Try to find matching user data
          Map<String, dynamic>? userData;
          String? userUID;

          // First try to find by matching the document ID with a user UID
          for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
            if (userDoc.id == attendanceDocId) {
              userUID = userDoc.id;
              userData = userDoc.data() as Map<String, dynamic>;
              break;
            }
          }

          // If not found by UID, try to find by EID
          if (userData == null) {
            for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
              Map<String, dynamic> user =
                  userDoc.data() as Map<String, dynamic>;
              if (user['Eid']?.toString() == eid) {
                userUID = userDoc.id;
                userData = user;
                break;
              }
            }
          }

          // Use user data if found, otherwise use attendance data
          String finalName = userData?['name']?.toString() ?? name;
          String finalEid = userData?['Eid']?.toString() ?? eid;
          String userEmail = userData?['email']?.toString() ?? 'N/A';
          String userDepartment = userData?['department']?.toString() ?? 'N/A';
          String? profileImageUrl = userData?['profileImageUrl'];
          String? profilePicBinary = userData?['profilePicBinary'];

          employeeList.add({
            'employeeId': userUID ?? attendanceDocId,
            'eid': finalEid,
            'name': finalName,
            'email': userEmail,
            'department': userDepartment,
            'profileImageUrl': profileImageUrl,
            'profilePicBinary': profilePicBinary,
            'attendanceRecords': attendanceData['records'],
            'presentDays': attendanceData['presentDays'],
            'halfDays': attendanceData['halfDays'],
            'absentDays': attendanceData['absentDays'],
          });

          print(
              'Loaded employee: $finalName ($finalEid) - Present: ${attendanceData['presentDays']}, Half Day: ${attendanceData['halfDays']}, Absent: ${attendanceData['absentDays']}');
        } catch (e) {
          print('Error processing attendance document $attendanceDocId: $e');
        }
      }

      setState(() {
        _employees = employeeList;
        _filteredEmployees = List.from(employeeList);
        _isLoading = false;
        print(
            'Successfully loaded ${employeeList.length} employees with attendance data');
      });
    } catch (e) {
      print('Error loading employees with attendance: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _loadEmployeeAttendanceRecordsWithEid(
      String userUID) async {
    try {
      // Get attendance from the structure: attendance/{UserUid}/dates/{Date}
      QuerySnapshot dateSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(userUID)
          .collection('dates')
          .orderBy(FieldPath.documentId, descending: true)
          .get();

      print(
          'Found ${dateSnapshot.docs.length} date records for user: $userUID');

      List<Map<String, dynamic>> records = [];
      String? eid;
      String? employeeName;
      int presentDays = 0;
      int halfDays = 0;
      int absentDays = 0;

      for (QueryDocumentSnapshot dateDoc in dateSnapshot.docs) {
        Map<String, dynamic> data = dateDoc.data() as Map<String, dynamic>;
        String dateId = dateDoc.id;

        print('Processing date: $dateId for user: $userUID');
        print('Date data fields: ${data.keys.toList()}');

        // Get EID from the first record (field name is 'Eid' not 'eid')
        if (eid == null && data.containsKey('Eid')) {
          eid = data['Eid'].toString();
          print('Found EID: $eid');
        }

        // Get employee name from the first record
        if (employeeName == null && data.containsKey('name')) {
          employeeName = data['name'].toString();
          print('Found employee name: $employeeName');
        }

        // Get attendance status from the data
        String attendanceStatus =
            data['attendance_status']?.toString() ?? 'Absent';

        print('Attendance status for $dateId: $attendanceStatus');

        // Count based on attendance_status field values from the database
        if (attendanceStatus.toLowerCase() == 'present') {
          presentDays++;
          print('Counted as present day');
        } else if (attendanceStatus.toLowerCase() == 'half day present') {
          halfDays++;
          print('Counted as half day');
        } else {
          absentDays++;
          print('Counted as absent day');
        }

        // Calculate hours for display using formattedTime field
        double hours = 0.0;
        if (data.containsKey('formattedTime') &&
            data['formattedTime'] != null) {
          try {
            String formattedTime = data['formattedTime'].toString();
            hours = _parseFormattedTimeToHours(formattedTime);
          } catch (e) {
            print('Error parsing formatted time: $e');
          }
        }

        records.add({
          'date': dateId,
          'checkInTime': data['checkInTime']?.toString() ?? 'Not recorded',
          'checkOutTime': data['checkOutTime']?.toString() ?? 'Not recorded',
          'elapsedTime': data['formattedTime']?.toString() ?? 'Not calculated',
          'hours': hours,
          'status': attendanceStatus,
          'attendance_status': attendanceStatus,
          'formattedCheckIn': _formatTime(data['checkInTime']),
          'formattedCheckOut': _formatTime(data['checkOutTime']),
        });
      }

      return {
        'eid': eid,
        'name': employeeName,
        'records': records,
        'presentDays': presentDays,
        'halfDays': halfDays,
        'absentDays': absentDays,
      };
    } catch (e) {
      print('Error loading attendance records for $userUID: $e');
      return {
        'eid': null,
        'name': null,
        'records': [],
        'presentDays': 0,
        'halfDays': 0,
        'absentDays': 0,
      };
    }
  }

  double _parseFormattedTimeToHours(String formattedTime) {
    try {
      // Parse format like "00'hrs':00'min':12'sec" from the database
      if (formattedTime.contains("'hrs'") && formattedTime.contains("'min'")) {
        RegExp regex = RegExp(r"(\d+)'hrs':(\d+)'min':(\d+)'sec'");
        Match? match = regex.firstMatch(formattedTime);
        if (match != null) {
          int hours = int.parse(match.group(1)!);
          int minutes = int.parse(match.group(2)!);
          int seconds = int.parse(match.group(3)!);
          return hours + (minutes / 60.0) + (seconds / 3600.0);
        }
      }
      // Fallback to existing parsing logic
      return _parseElapsedTimeToHours(formattedTime);
    } catch (e) {
      print('Error parsing formatted time "$formattedTime": $e');
    }
    return 0.0;
  }

  double _parseElapsedTimeToHours(String elapsedTime) {
    try {
      if (elapsedTime.contains('h') && elapsedTime.contains('m')) {
        RegExp regex = RegExp(r'(\d+)h\s*(\d+)m');
        Match? match = regex.firstMatch(elapsedTime);
        if (match != null) {
          int hours = int.parse(match.group(1)!);
          int minutes = int.parse(match.group(2)!);
          return hours + (minutes / 60.0);
        }
      } else if (elapsedTime.contains(':')) {
        List<String> parts = elapsedTime.split(':');
        if (parts.length == 2) {
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[1]);
          return hours + (minutes / 60.0);
        }
      } else if (elapsedTime.contains('h')) {
        String hoursStr = elapsedTime.replaceAll('h', '').trim();
        return double.parse(hoursStr);
      } else {
        return double.parse(elapsedTime);
      }
    } catch (e) {
      print('Error parsing elapsed time "$elapsedTime": $e');
    }
    return 0.0;
  }

  String _formatTime(dynamic timeData) {
    if (timeData == null) return 'Not recorded';

    try {
      if (timeData is Timestamp) {
        DateTime dateTime = timeData.toDate();
        return DateFormat('HH:mm:ss').format(dateTime);
      } else if (timeData is String) {
        return timeData;
      }
    } catch (e) {
      print('Error formatting time: $e');
    }
    return 'Not recorded';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'half day present':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'half day present':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    Uint8List? imageBytes;

    if (employee['profilePicBinary'] != null &&
        employee['profilePicBinary'].isNotEmpty) {
      try {
        imageBytes = base64Decode(employee['profilePicBinary']);
      } catch (e) {
        print('Error decoding image: $e');
      }
    }

    List<Map<String, dynamic>> attendanceRecords =
        List<Map<String, dynamic>>.from(employee['attendanceRecords'] ?? []);
    int presentDays = employee['presentDays'];
    int halfDays = employee['halfDays'];
    int absentDays = employee['absentDays'];
    int totalRecords = presentDays + halfDays + absentDays;

    double attendancePercentage = totalRecords > 0
        ? (presentDays + (halfDays * 0.5)) / totalRecords * 100
        : 0;

    return Card(
      margin: EdgeInsets.all(12),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: imageBytes != null
                      ? MemoryImage(imageBytes)
                      : (employee['profileImageUrl'] != null
                          ? NetworkImage(employee['profileImageUrl'])
                          : null),
                  child:
                      imageBytes == null && employee['profileImageUrl'] == null
                          ? Icon(Icons.person, size: 35)
                          : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee['name'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'EID: ${employee['eid']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        employee['email'],
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        employee['department'],
                        style: TextStyle(
                          color: Colors.blue[500],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: attendancePercentage >= 80
                            ? Colors.green
                            : attendancePercentage >= 60
                                ? Colors.orange
                                : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${attendancePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Attendance',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Attendance Statistics
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Present', presentDays.toString(), Colors.green),
                _buildStatItem('Half Day', halfDays.toString(), Colors.orange),
                _buildStatItem('Absent', absentDays.toString(), Colors.red),
              ],
            ),
          ),

          // Attendance Records
          if (attendanceRecords.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Attendance Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 300, // Fixed height for scrollable attendance records
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: attendanceRecords.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> record = attendanceRecords[index];
                  Color statusColor = _getStatusColor(record['status']);
                  IconData statusIcon = _getStatusIcon(record['status']);

                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date and Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(record['date']),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon,
                                          size: 14, color: statusColor),
                                      SizedBox(width: 4),
                                      Text(
                                        record['status'],
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            // Time Details
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimeInfo(
                                    'Check In',
                                    record['formattedCheckIn'],
                                    Icons.login,
                                    Colors.green,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _buildTimeInfo(
                                    'Check Out',
                                    record['formattedCheckOut'],
                                    Icons.logout,
                                    Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            // Duration
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 6),
                                  Text(
                                    'Duration: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${record['elapsedTime']} (${record['hours'].toStringAsFixed(1)}h)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No attendance records found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or EID...',
                prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blue[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blue[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),

          // Summary statistics
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[100]!, Colors.blue[200]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Employees',
                    _employees.length.toString(), Icons.people),
                _buildSummaryItem(
                    'Active',
                    _employees
                        .where((e) =>
                            (e['presentDays'] ?? 0) > 0 ||
                            (e['halfDays'] ?? 0) > 0)
                        .length
                        .toString(),
                    Icons.check_circle),
              ],
            ),
          ),

          // Employee list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading attendance data...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No employees found',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your search criteria',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filteredEmployees.length,
                        itemBuilder: (context, index) {
                          return _buildEmployeeCard(_filteredEmployees[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[700], size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
