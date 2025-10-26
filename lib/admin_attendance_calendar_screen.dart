import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';

class AttendanceCalendarScreen extends StatefulWidget {
  @override
  _AttendanceCalendarScreenState createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _debugFirestoreCollections(); // Debug first
    _loadEmployeesFromAttendance();
    _searchController.addListener(_filterEmployees);
  }

  // Debug method to check Firestore collections
  Future<void> _debugFirestoreCollections() async {
    print('=== DEBUGGING FIRESTORE COLLECTIONS ===');

    try {
      // Check attendance collection
      QuerySnapshot attendanceSnapshot =
          await FirebaseFirestore.instance.collection('attendance').get();
      print(
          'Attendance collection documents: ${attendanceSnapshot.docs.length}');
      for (var doc in attendanceSnapshot.docs) {
        print('  - Document ID: ${doc.id}');
        print('  - Document data: ${doc.data()}');
      }

      // Check users collection
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      print('Users collection documents: ${usersSnapshot.docs.length}');
      for (var doc in usersSnapshot.docs) {
        print('  - Document ID: ${doc.id}');
        print('  - Document data: ${doc.data()}');
      }

      // Check employees collection
      QuerySnapshot employeesSnapshot =
          await FirebaseFirestore.instance.collection('employees').get();
      print('Employees collection documents: ${employeesSnapshot.docs.length}');
      for (var doc in employeesSnapshot.docs) {
        print('  - Document ID: ${doc.id}');
        print('  - Document data: ${doc.data()}');
      }
    } catch (e) {
      print('Error debugging collections: $e');
    }

    print('=== END DEBUG ===');
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
                employee['eid'].toLowerCase().contains(query) ||
                employee['email'].toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadEmployeesFromAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: Print authentication status
      User? currentUser = FirebaseAuth.instance.currentUser;
      print(
          'Current authenticated user: ${currentUser?.uid ?? "NOT AUTHENTICATED"}');

      // Get all attendance documents - document IDs are the user IDs
      print('Starting to load attendance documents...');

      QuerySnapshot attendanceSnapshot =
          await FirebaseFirestore.instance.collection('attendance').get();

      print('Query completed successfully');
      print(
          'Total attendance documents found: ${attendanceSnapshot.docs.length}');

      // Extract unique user IDs from document IDs
      Set<String> uniqueEmployeeIds = {};
      for (var doc in attendanceSnapshot.docs) {
        uniqueEmployeeIds.add(doc.id); // Using document ID as user ID
        print('Found attendance document ID (User ID): ${doc.id}');
      }

      // If collection query only returned fewer documents than expected,
      // use the manual approach as fallback
      List<String> knownDocIds = [
        'CP1lmUpab5dcMJtl2YIwqYQUum42', // kaushik
        'a3rQ02C6qrMmMjzy51M7thhW4UJ3', // shandeep - corrected ID
      ];

      if (uniqueEmployeeIds.length < 2) {
        print('Using Manual Document IDs as Fallback');
        for (String docId in knownDocIds) {
          uniqueEmployeeIds.add(docId);
          print('Added document ID to employee list: $docId');
        }
      }

      print('Total unique employee IDs found: ${uniqueEmployeeIds.length}');

      // Fetch user details for each unique employee ID (User ID)
      List<Map<String, dynamic>> employeeList = [];

      for (String employeeId in uniqueEmployeeIds) {
        try {
          print('Fetching user data for User ID: $employeeId');
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(employeeId)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;

            String userName = userData['name'] ?? 'Unknown';
            String eid = userData['Eid'] ??
                employeeId; // Get EID from user data or use document ID
            print('Found user: $userName with EID: $eid');

            // Calculate attendance statistics using document ID
            Map<String, int> stats =
                await _calculateAttendanceStatsById(employeeId);

            employeeList.add({
              'employeeId': employeeId,
              'eid': eid,
              'name': userName,
              'profileImageUrl': userData['profileImageUrl'],
              'profilePicBinary': userData['profilePicBinary'],
              'email': userData['email'] ?? 'N/A',
              'presentDays': stats['presentDays'],
              'absentDays': stats['absentDays'],
              'halfDays': stats['halfDays'],
              'totalDays': stats['totalDays'],
            });
          } else {
            print('No user found for User ID: $employeeId');
          }
        } catch (e) {
          print('Error fetching user $employeeId: $e');
        }
      }

      // If no employees found from attendance, try loading from users collection directly
      if (employeeList.isEmpty) {
        print('No employees found from attendance, trying users collection...');
        try {
          QuerySnapshot usersSnapshot =
              await FirebaseFirestore.instance.collection('users').get();

          print('Users collection documents: ${usersSnapshot.docs.length}');

          for (var doc in usersSnapshot.docs) {
            try {
              Map<String, dynamic> userData =
                  doc.data() as Map<String, dynamic>;
              String userName = userData['name'] ?? 'Unknown';
              String eid = userData['Eid'] ?? doc.id;

              print(
                  'Found user from users collection: $userName with EID: $eid');

              Map<String, int> stats =
                  await _calculateAttendanceStatsById(doc.id);

              employeeList.add({
                'employeeId': doc.id,
                'eid': eid,
                'name': userName,
                'profileImageUrl': userData['profileImageUrl'],
                'profilePicBinary': userData['profilePicBinary'],
                'email': userData['email'] ?? 'N/A',
                'presentDays': stats['presentDays'],
                'absentDays': stats['absentDays'],
                'halfDays': stats['halfDays'],
                'totalDays': stats['totalDays'],
              });
            } catch (e) {
              print('Error processing user ${doc.id}: $e');
            }
          }
        } catch (e) {
          print('Error querying users collection: $e');
        }
      }

      setState(() {
        _employees = employeeList;
        _filteredEmployees = List.from(employeeList);
        _isLoading = false;
        print('Successfully loaded ${employeeList.length} employees');
      });
    } catch (e) {
      print('Error loading employees: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, int>> _calculateAttendanceStatsById(
      String employeeId) async {
    try {
      // Get attendance data from the subcollection structure: attendance/{employeeId}/dates/{date}
      QuerySnapshot datesSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(employeeId)
          .collection('dates')
          .get();

      int presentDays = 0;
      int halfDays = 0;
      int totalDays = datesSnapshot.docs.length;

      for (QueryDocumentSnapshot dateDoc in datesSnapshot.docs) {
        Map<String, dynamic> dayData = dateDoc.data() as Map<String, dynamic>;

        String elapsedTime = dayData['elapsedTime'] ?? '';
        String checkIn = dayData['checkInTime'] ?? '';

        // Only count if there's actual check-in data
        if (checkIn.isNotEmpty && checkIn != 'N/A') {
          if (elapsedTime.isNotEmpty && elapsedTime != 'N/A') {
            double hours = _parseElapsedTime(elapsedTime);
            if (hours >= 8.0) {
              presentDays++;
            } else if (hours > 0) {
              halfDays++;
            }
          } else {
            // If no elapsed time but has check-in, count as half day
            halfDays++;
          }
        }
      }

      // Calculate absent days (assuming working days in a month)
      int absentDays = _calculateAbsentDays(totalDays, presentDays, halfDays);

      return {
        'presentDays': presentDays,
        'absentDays': absentDays,
        'halfDays': halfDays,
        'totalDays': totalDays,
      };
    } catch (e) {
      print('Error calculating stats for $employeeId: $e');
      return {
        'presentDays': 0,
        'absentDays': 0,
        'halfDays': 0,
        'totalDays': 0,
      };
    }
  }

  double _parseElapsedTime(String elapsedTime) {
    try {
      // Parse format like "8h 30m" or "7:45" or "8.5"
      if (elapsedTime.contains('h')) {
        List<String> parts = elapsedTime.split('h');
        double hours = double.parse(parts[0].trim());
        if (parts.length > 1 && parts[1].contains('m')) {
          double minutes = double.parse(parts[1].replaceAll('m', '').trim());
          hours += minutes / 60;
        }
        return hours;
      } else if (elapsedTime.contains(':')) {
        List<String> parts = elapsedTime.split(':');
        double hours = double.parse(parts[0]);
        double minutes = double.parse(parts[1]);
        return hours + (minutes / 60);
      } else {
        return double.parse(elapsedTime);
      }
    } catch (e) {
      print('Error parsing elapsed time: $elapsedTime');
      return 0.0;
    }
  }

  int _calculateAbsentDays(int totalDays, int presentDays, int halfDays) {
    // This is a simplified calculation
    // In a real scenario, you might want to calculate based on actual working days
    int workingDaysInMonth = 22; // Approximate working days per month
    int attendedDays = presentDays + halfDays;
    return workingDaysInMonth - attendedDays;
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    Uint8List? imageBytes;

    // Fix the incomplete line that was causing the error
    if (employee['profilePicBinary'] != null &&
        employee['profilePicBinary'].isNotEmpty) {
      try {
        imageBytes = base64Decode(employee['profilePicBinary']);
      } catch (e) {
        print('Error decoding profile image: $e');
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to detailed attendance view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeAttendanceDetailScreen(
                employee: employee,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: imageBytes != null
                        ? MemoryImage(imageBytes)
                        : (employee['profileImageUrl'] != null &&
                                employee['profileImageUrl'].isNotEmpty
                            ? NetworkImage(employee['profileImageUrl'])
                            : null),
                    child: (imageBytes == null &&
                            (employee['profileImageUrl'] == null ||
                                employee['profileImageUrl'].isEmpty))
                        ? Icon(Icons.person, size: 30, color: Colors.blue[600])
                        : null,
                  ),
                  SizedBox(width: 16),
                  // Employee Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'EID: ${employee['eid']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          employee['email'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // View Details Icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Attendance Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Present',
                    employee['presentDays'].toString(),
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Half Day',
                    employee['halfDays'].toString(),
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'Absent',
                    employee['absentDays'].toString(),
                    Colors.red,
                  ),
                  _buildStatItem(
                    'Total',
                    employee['totalDays'].toString(),
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Attendance'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[700],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, EID, or email...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                SizedBox(height: 8),
                // Summary Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${_employees.length} Total Employees',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${_filteredEmployees.length} Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Employee List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading employee attendance data...'),
                      ],
                    ),
                  )
                : _filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No employees found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredEmployees.length,
                        itemBuilder: (context, index) {
                          return _buildEmployeeCard(_filteredEmployees[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _debugFirestoreCollections();
            },
            backgroundColor: Colors.orange[700],
            child: Icon(Icons.bug_report, color: Colors.white),
            tooltip: 'Debug Collections',
            heroTag: "debug",
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              _loadEmployeesFromAttendance();
            },
            backgroundColor: Colors.blue[700],
            child: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
            heroTag: "refresh",
          ),
        ],
      ),
    );
  }
}

// Detailed Attendance View Screen for Individual Employee
class EmployeeAttendanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EmployeeAttendanceDetailScreen({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  _EmployeeAttendanceDetailScreenState createState() =>
      _EmployeeAttendanceDetailScreenState();
}

class _EmployeeAttendanceDetailScreenState
    extends State<EmployeeAttendanceDetailScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = false;
  String _selectedYear = DateTime.now().year.toString();
  String _selectedMonth = DateTime.now().month.toString();
  List<String> _years = [];
  List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _generateYears();
    _loadAttendanceRecords();
  }

  void _generateYears() {
    int currentYear = DateTime.now().year;
    for (int i = currentYear - 2; i <= currentYear + 1; i++) {
      _years.add(i.toString());
    }
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(
          'Loading attendance records for User ID: ${widget.employee['employeeId']}');

      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(widget.employee['employeeId'])
          .collection('dates')
          .get();

      List<Map<String, dynamic>> records = [];

      for (QueryDocumentSnapshot doc in attendanceSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Parse the date from document ID (format: YYYY-MM-DD)
        String dateStr = doc.id;
        DateTime? recordDate;

        try {
          recordDate = DateTime.parse(dateStr);
        } catch (e) {
          print('Error parsing date $dateStr: $e');
          continue;
        }

        // Filter by selected year and month
        if (recordDate.year.toString() == _selectedYear &&
            recordDate.month.toString() == _selectedMonth) {
          String checkInTime = data['checkInTime'] ?? 'N/A';
          String checkOutTime = data['checkOutTime'] ?? 'N/A';
          String elapsedTime = data['elapsedTime'] ?? 'N/A';
          String status = data['status'] ?? 'unknown';

          // Determine attendance status
          String attendanceStatus = 'Absent';
          if (checkInTime != 'N/A' && checkInTime.isNotEmpty) {
            if (elapsedTime != 'N/A' && elapsedTime.isNotEmpty) {
              double hours = _parseElapsedTime(elapsedTime);
              if (hours >= 8.0) {
                attendanceStatus = 'Present';
              } else if (hours > 0) {
                attendanceStatus = 'Half Day';
              }
            } else {
              attendanceStatus = 'Half Day';
            }
          }

          records.add({
            'date': recordDate,
            'dateStr': dateStr,
            'checkInTime': checkInTime,
            'checkOutTime': checkOutTime,
            'elapsedTime': elapsedTime,
            'status': status,
            'attendanceStatus': attendanceStatus,
          });
        }
      }

      // Sort records by date (newest first)
      records.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });

      print(
          'Loaded ${records.length} attendance records for $_selectedMonth $_selectedYear');
    } catch (e) {
      print('Error loading attendance records: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _parseElapsedTime(String elapsedTime) {
    try {
      if (elapsedTime.contains('h')) {
        List<String> parts = elapsedTime.split('h');
        double hours = double.parse(parts[0].trim());
        if (parts.length > 1 && parts[1].contains('m')) {
          double minutes = double.parse(parts[1].replaceAll('m', '').trim());
          hours += minutes / 60;
        }
        return hours;
      } else if (elapsedTime.contains(':')) {
        List<String> parts = elapsedTime.split(':');
        double hours = double.parse(parts[0]);
        double minutes = double.parse(parts[1]);
        return hours + (minutes / 60);
      } else {
        return double.parse(elapsedTime);
      }
    } catch (e) {
      print('Error parsing elapsed time: $elapsedTime');
      return 0.0;
    }
  }

  Widget _buildAttendanceRecord(Map<String, dynamic> record) {
    Color statusColor;
    IconData statusIcon;

    switch (record['attendanceStatus']) {
      case 'Present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Half Day':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'Absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            // Date and Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(record['date']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Check-in: ${record['checkInTime'] != 'N/A' ? DateFormat('HH:mm').format(DateTime.parse(record['checkInTime'])) : 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Check-out: ${record['checkOutTime'] != 'N/A' ? DateFormat('HH:mm').format(DateTime.parse(record['checkOutTime'])) : 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (record['elapsedTime'] != 'N/A' &&
                      record['elapsedTime'].isNotEmpty)
                    Text(
                      'Duration: ${record['elapsedTime']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                record['attendanceStatus'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.employee['name']} - Attendance Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Employee Info Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, color: Colors.blue[600]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employee['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'EID: ${widget.employee['eid']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.employee['email'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Month/Year Selector
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: _months.asMap().entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: (entry.key + 1).toString(),
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value!;
                      });
                      _loadAttendanceRecords();
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: _years.map((year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value!;
                      });
                      _loadAttendanceRecords();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Attendance Records List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading attendance records...'),
                      ],
                    ),
                  )
                : _attendanceRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No attendance records found for $_selectedMonth $_selectedYear',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _attendanceRecords.length,
                        itemBuilder: (context, index) {
                          return _buildAttendanceRecord(
                              _attendanceRecords[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
