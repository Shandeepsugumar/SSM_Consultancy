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
    _loadEmployeesFromAttendance();
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
            .where((employee) => employee['name'].toLowerCase().contains(query))
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
        print('Found attendance document ID: ${doc.id}');
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

      // Fetch user details for each unique employee ID
      List<Map<String, dynamic>> employeeList = [];

      for (String employeeId in uniqueEmployeeIds) {
        try {
          print('Fetching user data for ID: $employeeId');
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(employeeId)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;

            String userName = userData['name'] ?? 'Unknown';
            print('Found user: $userName for ID: $employeeId');

            // Calculate attendance statistics using document ID
            Map<String, int> stats =
                await _calculateAttendanceStatsById(employeeId);

            employeeList.add({
              'employeeId': employeeId,
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
            print('No user found for ID: $employeeId');
          }
        } catch (e) {
          print('Error fetching user $employeeId: $e');
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

    if (employee['profilePicBinary'] != null &&
        employee['profilePicBinary'].isNotEmpty) {
      try {
        imageBytes = base64Decode(employee['profilePicBinary']);
      } catch (e) {
        print('Error decoding image: $e');
      }
    }

    int presentDays = employee['presentDays'] ?? 0;
    int absentDays = employee['absentDays'] ?? 0;
    int halfDays = employee['halfDays'] ?? 0;
    int totalDays = employee['totalDays'] ?? 0;

    double attendancePercentage =
        totalDays > 0 ? (presentDays + (halfDays * 0.5)) / totalDays * 100 : 0;

    return Card(
      margin: EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEmployeeAttendanceDetails(employee),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: imageBytes != null
                        ? MemoryImage(imageBytes)
                        : (employee['profileImageUrl'] != null
                            ? NetworkImage(employee['profileImageUrl'])
                            : null),
                    child: imageBytes == null &&
                            employee['profileImageUrl'] == null
                        ? Icon(Icons.person, size: 30)
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          employee['email'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.trending_up,
                                color: attendancePercentage >= 80
                                    ? Colors.green
                                    : attendancePercentage >= 60
                                        ? Colors.orange
                                        : Colors.red,
                                size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${attendancePercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: attendancePercentage >= 80
                                    ? Colors.green
                                    : attendancePercentage >= 60
                                        ? Colors.orange
                                        : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                      'Present', presentDays.toString(), Colors.green),
                  _buildStatColumn(
                      'Half Day', halfDays.toString(), Colors.orange),
                  _buildStatColumn('Absent', absentDays.toString(), Colors.red),
                  _buildStatColumn('Total', totalDays.toString(), Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
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
          ),
        ),
      ],
    );
  }

  void _showEmployeeAttendanceDetails(Map<String, dynamic> employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeAttendanceDetailScreen(
          employeeId: employee['employeeId'],
          employeeName: employee['name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Statistics summary
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Employees',
                    _employees.length.toString(), Icons.people),
                _buildSummaryItem(
                    'Active',
                    _employees
                        .where((e) => (e['totalDays'] ?? 0) > 0)
                        .length
                        .toString(),
                    Icons.check_circle),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Employee list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
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
        Icon(icon, color: Colors.blue[700], size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
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
}

// Enhanced Employee Attendance Detail Screen with Calendar View and Date Filtering
class EmployeeAttendanceDetailScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeAttendanceDetailScreen({
    Key? key,
    required this.employeeId,
    required this.employeeName,
  }) : super(key: key);

  @override
  _EmployeeAttendanceDetailScreenState createState() =>
      _EmployeeAttendanceDetailScreenState();
}

class _EmployeeAttendanceDetailScreenState
    extends State<EmployeeAttendanceDetailScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(
          'Loading attendance records for employee: ${widget.employeeId} (${widget.employeeName})');

      // Fetch attendance records from subcollection: attendance/{employeeId}/dates
      QuerySnapshot dateSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(widget.employeeId)
          .collection('dates')
          .orderBy(FieldPath.documentId, descending: true)
          .get();

      print('Found ${dateSnapshot.docs.length} date documents');

      List<Map<String, dynamic>> records = [];

      for (QueryDocumentSnapshot dateDoc in dateSnapshot.docs) {
        Map<String, dynamic> data = dateDoc.data() as Map<String, dynamic>;
        String dateId = dateDoc.id;

        print('Processing date document: $dateId');
        print('Document data: $data');

        // Ensure we have the required fields
        if (data.containsKey('checkInTime') ||
            data.containsKey('checkOutTime')) {
          // Calculate status based on work hours
          double hours = 0.0;
          String status = 'Absent';

          if (data.containsKey('elapsedTime') && data['elapsedTime'] != null) {
            try {
              // Parse elapsed time (format: "8h 30m" or "8:30" or similar)
              String elapsedTime = data['elapsedTime'].toString();
              hours = _parseElapsedTimeToHours(elapsedTime);
            } catch (e) {
              print('Error parsing elapsed time: $e');
            }
          }

          // Determine status based on hours worked
          if (hours >= 8.0) {
            status = 'Full Day';
          } else if (hours >= 4.0) {
            status = 'Half Day';
          } else if (hours > 0) {
            status = 'Short Day';
          }

          records.add({
            'date': dateId,
            'checkInTime': data['checkInTime']?.toString() ?? 'Not recorded',
            'checkOutTime': data['checkOutTime']?.toString() ?? 'Not recorded',
            'elapsedTime': data['elapsedTime']?.toString() ?? 'Not calculated',
            'hours': hours,
            'status': status,
          });
        }
      }

      print('Processed ${records.length} attendance records');

      setState(() {
        _attendanceRecords = records;
        _filteredRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading attendance records: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRecordsByDateRange() {
    if (_selectedDateRange == null) {
      setState(() {
        _filteredRecords = _attendanceRecords;
      });
      return;
    }

    List<Map<String, dynamic>> filtered = _attendanceRecords.where((record) {
      try {
        DateTime recordDate = DateTime.parse(record['date']);
        DateTime startDate = DateTime(_selectedDateRange!.start.year,
            _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        DateTime endDate = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23,
            59,
            59);

        return recordDate.isAfter(startDate.subtract(Duration(days: 1))) &&
            recordDate.isBefore(endDate.add(Duration(days: 1)));
      } catch (e) {
        print('Error parsing date for filtering: $e');
        return false;
      }
    }).toList();

    setState(() {
      _filteredRecords = filtered;
    });
  }

  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _filterRecordsByDateRange();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
      _filteredRecords = _attendanceRecords;
    });
  }

  double _parseElapsedTimeToHours(String elapsedTime) {
    try {
      // Handle different formats: "8h 30m", "8:30", "8.5h", etc.
      if (elapsedTime.contains('h') && elapsedTime.contains('m')) {
        // Format: "8h 30m"
        RegExp regex = RegExp(r'(\d+)h\s*(\d+)m');
        Match? match = regex.firstMatch(elapsedTime);
        if (match != null) {
          int hours = int.parse(match.group(1)!);
          int minutes = int.parse(match.group(2)!);
          return hours + (minutes / 60.0);
        }
      } else if (elapsedTime.contains(':')) {
        // Format: "8:30"
        List<String> parts = elapsedTime.split(':');
        if (parts.length == 2) {
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[1]);
          return hours + (minutes / 60.0);
        }
      } else if (elapsedTime.contains('h')) {
        // Format: "8.5h"
        String hoursStr = elapsedTime.replaceAll('h', '').trim();
        return double.parse(hoursStr);
      } else {
        // Try to parse as a decimal number
        return double.parse(elapsedTime);
      }
    } catch (e) {
      print('Error parsing elapsed time "$elapsedTime": $e');
    }
    return 0.0;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'full day':
        return Colors.green;
      case 'half day':
        return Colors.orange;
      case 'short day':
        return Colors.amber;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'full day':
        return Icons.check_circle;
      case 'half day':
        return Icons.schedule;
      case 'short day':
        return Icons.access_time;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate summary statistics for filtered records
    int fullDays = _filteredRecords
        .where((record) => record['status'] == 'Full Day')
        .length;
    int halfDays = _filteredRecords
        .where((record) => record['status'] == 'Half Day')
        .length;
    int shortDays = _filteredRecords
        .where((record) => record['status'] == 'Short Day')
        .length;
    int totalRecords = _filteredRecords.length;
    double totalHours =
        _filteredRecords.fold(0.0, (sum, record) => sum + record['hours']);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.employeeName} - Calendar View'),
        backgroundColor: Colors.blue[100],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _selectDateRange,
            tooltip: 'Filter by Date Range',
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearDateFilter,
              tooltip: 'Clear Filter',
            ),
        ],
      ),
      body: Column(
        children: [
          // Date filter indicator
          if (_selectedDateRange != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Filtered: ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                    style: TextStyle(
                        color: Colors.blue[700], fontWeight: FontWeight.w500),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: _clearDateFilter,
                    child: Text('Clear'),
                  ),
                ],
              ),
            ),

          // Enhanced Summary section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Attendance Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                // First row of summary cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCard(
                        'Full Days', fullDays.toString(), Colors.green[100]!),
                    _buildSummaryCard(
                        'Half Days', halfDays.toString(), Colors.orange[100]!),
                    _buildSummaryCard(
                        'Short Days', shortDays.toString(), Colors.amber[100]!),
                  ],
                ),
                SizedBox(height: 12),
                // Second row of summary cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCard('Total Records', totalRecords.toString(),
                        Colors.blue[100]!),
                    _buildSummaryCard('Total Hours',
                        totalHours.toStringAsFixed(1), Colors.purple[100]!),
                    _buildSummaryCard(
                        'Avg Hours',
                        totalRecords > 0
                            ? (totalHours / totalRecords).toStringAsFixed(1)
                            : '0.0',
                        Colors.teal[100]!),
                  ],
                ),
              ],
            ),
          ),

          // Attendance records
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              _selectedDateRange != null
                                  ? 'No attendance records found for selected date range'
                                  : 'No attendance records found',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedDateRange != null) ...[
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _clearDateFilter,
                                child: Text('Show All Records'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> record = _filteredRecords[index];
                          Color statusColor = _getStatusColor(record['status']);
                          IconData statusIcon =
                              _getStatusIcon(record['status']);

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date and Status header
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _formatDate(record['date']),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon,
                                                  size: 16, color: statusColor),
                                              SizedBox(width: 4),
                                              Text(
                                                record['status'],
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),

                                    // Time details
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTimeDetail(
                                            'Check In',
                                            record['checkInTime'],
                                            Icons.login,
                                            Colors.green,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: _buildTimeDetail(
                                            'Check Out',
                                            record['checkOutTime'],
                                            Icons.logout,
                                            Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),

                                    // Duration details
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule,
                                              size: 20, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text(
                                            'Duration: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            '${record['elapsedTime']} (${record['hours'].toStringAsFixed(1)}h)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700],
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
        ],
      ),
    );
  }

  Widget _buildTimeDetail(
      String label, String time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color backgroundColor) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy (EEEE)').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
