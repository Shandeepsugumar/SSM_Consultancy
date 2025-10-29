import 'package:consultancy/admin_waiting_for_approval.dart'
    as waiting_approval;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'admin_attendance_simple.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:consultancy/loginpage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:consultancy/admin_attendance_calendar_enhance.dart';
import 'package:consultancy/admin_comprehensive_attendance_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'employee_names_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  final List<Widget> _pages = [
    HomeScreen(),
    SchedulePage(),
    EmployeeAttendancePage(), // Use our fixed EmployeeAttendancePage
    TrackingScreen(),
    // AccountsScreen(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          _getTitle(_selectedIndex),
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
        toolbarHeight: 60, // Increase the height of the AppBar
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
        ),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.black54,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        iconSize: 28,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "HOME",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: "Attendance",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: "Tracking",
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.account_balance_outlined),
          //   activeIcon: Icon(Icons.account_balance),
          //   label: "Accounts",
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 1:
        return "SCHEDULES";
      case 2:
        return "ATTENDANCE";
      case 3:
        return "Tracking";
      case 4:
        return "PROFILE";
      default:
        return "Welcome To SSM";
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout(context);
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false, // This will remove all routes from the stack
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }
}

// Screens
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              DashboardPage(),
              _buildButton(
                context,
                "Active User",
                Icons.check_circle,
                Colors.green,
                "/activeUsers",
              ),
              _buildButton(
                context,
                "Inactive User",
                Icons.cancel,
                Colors.red,
                "/inactiveUsers",
              ),
              _buildButton(
                context,
                "Waiting for Approval",
                Icons.hourglass_top,
                Colors.orange,
                "UserCard",
              ), // Updated Route
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: color, size: 28),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
          onTap: () {
            if (route == "UserCard") {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => waiting_approval.UsersList()),
              );
            } else if (route == "/activeUsers") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ActiveUsersPage()),
              );
            } else if (route == "/inactiveUsers") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InactiveUsersPage()),
              );
            } else {
              Navigator.pushNamed(context, route);
            }
          },
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  String? _profileImageUrl;
  String? _profilePicBinary;
  Uint8List? _profileImageBytes;

  // Cache admin data to avoid repeated fetches
  static Map<String, dynamic>? _cachedAdminData;
  static String? _cachedUserId;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Check if we have cached data for this user
    if (_cachedAdminData != null && _cachedUserId == user.uid) {
      _useCachedData();
      return;
    }

    await fetchUserName();
  }

  void _useCachedData() {
    setState(() {
      userData = _cachedAdminData;
      _profileImageUrl = userData!["profileImageUrl"];
      _profilePicBinary = userData!["profilePicBinary"];

      if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
        _decodeProfileImage();
      }
      _isLoading = false;
    });
  }

  Future<void> _decodeProfileImage() async {
    if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
      try {
        // Decode base64 in a separate isolate/compute to avoid blocking UI
        _profileImageBytes = base64Decode(_profilePicBinary!);
      } catch (e) {
        print("Error decoding base64: $e");
      }
    }
  }

  Future<void> fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print("📥 Fetching admin data for: ${user.uid}");

      // Add timeout to prevent indefinite loading
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Admins")
          .doc(user.uid)
          .get(GetOptions(source: Source.cache)) // Try cache first
          .timeout(Duration(seconds: 3))
          .catchError((e) async {
        print("⚠️ Cache miss, fetching from server...");
        // If cache fails, fetch from server with longer timeout
        return await FirebaseFirestore.instance
            .collection("Admins")
            .doc(user.uid)
            .get(GetOptions(source: Source.server))
            .timeout(Duration(seconds: 10));
      });

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Cache the data
        _cachedAdminData = data;
        _cachedUserId = user.uid;

        print("✅ Admin data loaded successfully");

        setState(() {
          userData = data;
          _profileImageUrl = userData!["profileImageUrl"];
          _profilePicBinary = userData!["profilePicBinary"];
          _isLoading = false;
        });

        // Decode image asynchronously to avoid blocking UI
        if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
          _decodeProfileImageAsync();
        }
      } else {
        print("❌ Admin document not found for user: ${user.uid}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching admin data: $e");
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile. Pull down to refresh.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _refreshAdminData,
            ),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _decodeProfileImageAsync() async {
    try {
      final bytes = base64Decode(_profilePicBinary!);
      if (mounted) {
        setState(() {
          _profileImageBytes = bytes;
        });
      }
    } catch (e) {
      print("Error decoding base64: $e");
    }
  }

  // Method to refresh admin data (clears cache and fetches fresh data)
  Future<void> _refreshAdminData() async {
    _clearCache();
    setState(() {
      _isLoading = true;
    });
    await fetchUserName();
  }

  // Method to clear cached admin data
  static void _clearCache() {
    _cachedAdminData = null;
    _cachedUserId = null;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAdminData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _isLoading
                  ? Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading admin profile...'),
                          ],
                        ),
                      ),
                    )
                  : _buildProfileSection(),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: _profileImageBytes != null
                ? MemoryImage(_profileImageBytes!)
                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? NetworkImage(_profileImageUrl!)
                    : null),
            child: (_profileImageUrl == null && _profileImageBytes == null)
                ? Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData != null
                      ? userData!["FirstName"] ?? "Unknown"
                      : "Unknown",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Administrator",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white70),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(userData: userData!),
                ),
              );

              if (result == true) {
                await _refreshAdminData();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ... (SchedulePage code remains the same, truncated for brevity)

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _numWorkersController = TextEditingController();
  final TextEditingController _totalHoursController = TextEditingController();

  List<MultiSelectItem<Map<String, dynamic>>> _employeeItems = [];
  List<Map<String, dynamic>> _selectedEmployees = [];
  Map<String, dynamic>? _latestSchedule;

  // Status is always 'active' by default
  final String _selectedStatus = 'active';

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchLatestSchedule(); // new

    // Add listeners to calculate work hours automatically
    _startTimeController.addListener(_calculateWorkHours);
    _endTimeController.addListener(_calculateWorkHours);
  }

  @override
  void dispose() {
    _startTimeController.removeListener(_calculateWorkHours);
    _endTimeController.removeListener(_calculateWorkHours);
    _startTimeController.dispose();
    _endTimeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _branchNameController.dispose();
    _numWorkersController.dispose();
    _totalHoursController.dispose();
    super.dispose();
  }

  // Function to calculate work hours between start and end time
  void _calculateWorkHours() {
    if (_startTimeController.text.isNotEmpty &&
        _endTimeController.text.isNotEmpty) {
      try {
        // Parse time strings to TimeOfDay
        TimeOfDay startTime = _parseTimeString(_startTimeController.text);
        TimeOfDay endTime = _parseTimeString(_endTimeController.text);

        // Calculate total minutes
        int startMinutes = startTime.hour * 60 + startTime.minute;
        int endMinutes = endTime.hour * 60 + endTime.minute;

        // Handle case where end time is next day (e.g., night shift)
        if (endMinutes < startMinutes) {
          endMinutes += 24 * 60; // Add 24 hours
        }

        int totalMinutes = endMinutes - startMinutes;

        // Convert to hours and minutes
        int hours = totalMinutes ~/ 60;
        int minutes = totalMinutes % 60;

        // Format the result
        String workHours;
        if (minutes == 0) {
          workHours = '$hours';
        } else {
          double decimalHours = hours + (minutes / 60.0);
          workHours = decimalHours.toStringAsFixed(2);
        }

        // Update the total hours field
        _totalHoursController.text = workHours;

        print(
            '🕐 Calculated work hours: $workHours hours (Start: ${_startTimeController.text}, End: ${_endTimeController.text})');
      } catch (e) {
        print('⚠️ Error calculating work hours: $e');
        // Don't clear the field in case of error, user might want to enter manually
      }
    }
  }

  // Helper function to parse time string (handles both 12-hour and 24-hour formats)
  TimeOfDay _parseTimeString(String timeString) {
    try {
      // Remove any extra spaces
      timeString = timeString.trim();

      // Handle 12-hour format (e.g., "2:30 PM", "10:15 AM")
      if (timeString.toUpperCase().contains('AM') ||
          timeString.toUpperCase().contains('PM')) {
        bool isPM = timeString.toUpperCase().contains('PM');
        String cleanTime = timeString.replaceAll(RegExp(r'[APMapm\s]'), '');

        List<String> parts = cleanTime.split(':');
        int hour = int.parse(parts[0]);
        int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

        // Convert to 24-hour format
        if (isPM && hour != 12) {
          hour += 12;
        } else if (!isPM && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
      // Handle 24-hour format (e.g., "14:30", "09:15")
      else {
        List<String> parts = timeString.split(':');
        int hour = int.parse(parts[0]);
        int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      throw FormatException('Invalid time format: $timeString');
    }
  }

  Future<void> _fetchLatestSchedule() async {
    final scheduleSnapshot = await FirebaseFirestore.instance
        .collection('schedule')
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    if (scheduleSnapshot.docs.isNotEmpty) {
      final scheduleData = scheduleSnapshot.docs.first.data();
      final List<dynamic> assignedEids =
          scheduleData['assignedEmployees'] ?? [];

      List<String> resolvedEmployeeNames = [];

      for (var eid in assignedEids) {
        try {
          // Query users collection by Eid field instead of document ID
          final userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('Eid', isEqualTo: eid)
              .get();

          if (userQuery.docs.isNotEmpty) {
            final userDoc = userQuery.docs.first;
            final data = userDoc.data();
            resolvedEmployeeNames.add(
              '${data['Eid'] ?? 'N/A'} - ${data['name'] ?? 'Unknown'}',
            );
          } else {
            resolvedEmployeeNames.add('$eid - Unknown');
          }
        } catch (e) {
          print('Error fetching user data for eid $eid: $e');
          resolvedEmployeeNames.add('Error loading user');
        }
      }

      if (mounted) {
        setState(() {
          _latestSchedule = {
            ...scheduleData,
            'resolvedEmployeeNames': resolvedEmployeeNames,
          };
        });
      }
    }
  }

  void _fetchEmployees() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      print('Fetched ${snapshot.docs.length} employees from Firestore');

      List<Map<String, dynamic>> employees = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Employee data for ${doc.id}: $data');
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unknown',
          'Eid': data['Eid'] ?? 'N/A',
        };
      }).toList();

      print('Processed employees: $employees');

      if (mounted) {
        setState(() {
          _employeeItems = employees
              .map(
                (e) => MultiSelectItem<Map<String, dynamic>>(
                  e,
                  '${e['Eid']} - ${e['name']}',
                ),
              )
              .toList();
        });
        print('Set ${_employeeItems.length} employee items');
      }
    } catch (e) {
      print('Error fetching employees: $e');
      if (mounted) {
        setState(() {
          _employeeItems = [];
        });
      }
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = "${picked.year}-${picked.month}-${picked.day}";
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = picked.format(context);
    }
  }

  Future<void> _submitSchedule() async {
    if (_formKey.currentState!.validate() && _selectedEmployees.isNotEmpty) {
      List<String> selectedEids =
          _selectedEmployees.map((e) => e['Eid'].toString()).toList();

      // Show loading dialog while checking for conflicts
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Checking schedule conflicts...'),
            ],
          ),
        ),
      );

      try {
        // Check for schedule conflicts
        List<String> conflictingEmployees =
            await _checkScheduleConflicts(selectedEids);

        // Close loading dialog
        Navigator.pop(context);

        if (conflictingEmployees.isNotEmpty) {
          // Show conflict dialog
          _showConflictDialog(conflictingEmployees);
          return;
        }

        // No conflicts, proceed with schedule creation
        await FirebaseFirestore.instance.collection('schedule').add({
          'startTime': _startTimeController.text,
          'endTime': _endTimeController.text,
          'startDate': _startDateController.text,
          'endDate': _endDateController.text,
          'branchName': _branchNameController.text,
          'numberOfWorkers': int.parse(_numWorkersController.text),
          'totalHours': _totalHoursController.text,
          'assignedEmployees': selectedEids,
          'status': _selectedStatus, // Use selected status
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Schedule Created Successfully')),
        );
        _fetchLatestSchedule();
        _formKey.currentState!.reset();
        _selectedEmployees.clear();
        // Reset worker count when form is reset
        _numWorkersController.clear();
        // Status remains 'active' by default
        setState(() {});
      } catch (e) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        print("🔥 Firestore operation failed: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Please fill all fields and select employees'),
        ),
      );
    }
  }

  // Method to check for schedule conflicts
  Future<List<String>> _checkScheduleConflicts(
      List<String> selectedEids) async {
    List<String> conflictingEmployees = [];

    try {
      // Get the new schedule details
      DateTime newStartDate = _parseDate(_startDateController.text);
      DateTime newEndDate = _parseDate(_endDateController.text);
      TimeOfDay newStartTime = _parseTimeString(_startTimeController.text);
      TimeOfDay newEndTime = _parseTimeString(_endTimeController.text);

      // Query all existing schedules
      QuerySnapshot existingSchedules =
          await FirebaseFirestore.instance.collection('schedule').get();

      for (var scheduleDoc in existingSchedules.docs) {
        Map<String, dynamic> scheduleData =
            scheduleDoc.data() as Map<String, dynamic>;

        // Check if this schedule is already completed/done
        String scheduleStatus = scheduleData['status']?.toString() ?? '';
        if (scheduleStatus.toLowerCase() == 'done' ||
            scheduleStatus.toLowerCase() == 'completed') {
          continue; // Skip completed schedules
        }

        // Get existing schedule details
        List<String> existingEids =
            List<String>.from(scheduleData['assignedEmployees'] ?? []);
        DateTime existingStartDate =
            _parseDate(scheduleData['startDate']?.toString() ?? '');
        DateTime existingEndDate =
            _parseDate(scheduleData['endDate']?.toString() ?? '');
        TimeOfDay existingStartTime =
            _parseTimeString(scheduleData['startTime']?.toString() ?? '');
        TimeOfDay existingEndTime =
            _parseTimeString(scheduleData['endTime']?.toString() ?? '');

        // Check for employee overlap
        List<String> overlappingEmployees =
            selectedEids.where((eid) => existingEids.contains(eid)).toList();

        if (overlappingEmployees.isNotEmpty) {
          // Check for date and time conflicts
          if (_hasDateTimeConflict(
            newStartDate,
            newEndDate,
            newStartTime,
            newEndTime,
            existingStartDate,
            existingEndDate,
            existingStartTime,
            existingEndTime,
          )) {
            // Add conflicting employees with their names
            for (String eid in overlappingEmployees) {
              String employeeName = await _getEmployeeNameByEid(eid);
              if (!conflictingEmployees.contains('$eid - $employeeName')) {
                conflictingEmployees.add('$eid - $employeeName');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error checking schedule conflicts: $e');
      throw e;
    }

    return conflictingEmployees;
  }

  // Method to parse date string to DateTime
  DateTime _parseDate(String dateString) {
    try {
      List<String> parts = dateString.split('-');
      if (parts.length == 3) {
        return DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (e) {
      print('Error parsing date: $dateString');
    }
    return DateTime.now();
  }

  // Method to check if there's a date and time conflict
  bool _hasDateTimeConflict(
    DateTime newStartDate,
    DateTime newEndDate,
    TimeOfDay newStartTime,
    TimeOfDay newEndTime,
    DateTime existingStartDate,
    DateTime existingEndDate,
    TimeOfDay existingStartTime,
    TimeOfDay existingEndTime,
  ) {
    // Check if dates overlap
    bool dateOverlap = !(newEndDate.isBefore(existingStartDate) ||
        newStartDate.isAfter(existingEndDate));

    if (!dateOverlap) {
      return false; // No date overlap, no conflict
    }

    // If dates overlap, check time overlap
    // Convert TimeOfDay to minutes for easier comparison
    int newStartMinutes = newStartTime.hour * 60 + newStartTime.minute;
    int newEndMinutes = newEndTime.hour * 60 + newEndTime.minute;
    int existingStartMinutes =
        existingStartTime.hour * 60 + existingStartTime.minute;
    int existingEndMinutes = existingEndTime.hour * 60 + existingEndTime.minute;

    // Handle overnight shifts
    if (newEndMinutes < newStartMinutes) {
      newEndMinutes += 24 * 60;
    }
    if (existingEndMinutes < existingStartMinutes) {
      existingEndMinutes += 24 * 60;
    }

    // Check time overlap
    bool timeOverlap = !(newEndMinutes <= existingStartMinutes ||
        newStartMinutes >= existingEndMinutes);

    return timeOverlap;
  }

  // Method to get employee name by Eid
  Future<String> _getEmployeeNameByEid(String eid) async {
    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('Eid', isEqualTo: eid)
          .get();

      if (userQuery.docs.isNotEmpty) {
        Map<String, dynamic> userData =
            userQuery.docs.first.data() as Map<String, dynamic>;
        return userData['name'] ?? 'Unknown';
      }
    } catch (e) {
      print('Error getting employee name for Eid $eid: $e');
    }
    return 'Unknown';
  }

  // Method to show conflict dialog
  void _showConflictDialog(List<String> conflictingEmployees) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              'Schedule Conflict!',
              style: TextStyle(
                color: Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cannot assign the following employees because they are already assigned to another work during the same time period:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_off,
                            color: Colors.red[600], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Conflicting Employees:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ...conflictingEmployees
                        .map((employee) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.circle,
                                      size: 8, color: Colors.red[600]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      employee,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Solutions:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Remove conflicting employees from selection\n• Choose different dates/times\n• Wait until their current work is marked as "done"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to auto-update the number of workers based on selected employees
  void _updateWorkerCount() {
    int selectedCount = _selectedEmployees.length;
    _numWorkersController.text = selectedCount.toString();

    print(
        '🔢 Auto-updated worker count to: $selectedCount (based on ${_selectedEmployees.length} selected employees)');
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType type,
    IconData? icon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly,
        onTap: onTap,
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildScheduleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                '📋 Work Schedule Form',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              label: 'Start Time',
                              controller: _startTimeController,
                              type: TextInputType.text,
                              icon: Icons.access_time,
                              onTap: () => _pickTime(_startTimeController),
                              readOnly: true,
                            ),
                            _buildTextField(
                              label: 'End Time',
                              controller: _endTimeController,
                              type: TextInputType.text,
                              icon: Icons.access_time_filled,
                              onTap: () => _pickTime(_endTimeController),
                              readOnly: true,
                            ),
                            _buildTextField(
                              label: 'Start Date',
                              controller: _startDateController,
                              type: TextInputType.text,
                              icon: Icons.calendar_today,
                              onTap: () => _pickDate(_startDateController),
                              readOnly: true,
                            ),
                            _buildTextField(
                              label: 'End Date',
                              controller: _endDateController,
                              type: TextInputType.text,
                              icon: Icons.date_range,
                              onTap: () => _pickDate(_endDateController),
                              readOnly: true,
                            ),
                            _buildTextField(
                              label: 'Branch Name',
                              controller: _branchNameController,
                              type: TextInputType.text,
                              icon: Icons.location_city,
                            ),
                            _buildTextField(
                              label: 'Number of Workers (Auto-calculated)',
                              controller: _numWorkersController,
                              type: TextInputType.number,
                              icon: Icons.people,
                            ),
                            if (_selectedEmployees.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 12, top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Automatically set to ${_selectedEmployees.length} based on selected employees',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            _buildTextField(
                              label: 'Total Work Hours (Auto-calculated)',
                              controller: _totalHoursController,
                              type: TextInputType.number,
                              icon: Icons.timelapse,
                            ),
                            if (_totalHoursController.text.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 12, top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Automatically calculated from start and end time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 16),
                            Text(
                              '👥 Select Employees',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            MultiSelectDialogField(
                              items: _employeeItems,
                              title: Text(
                                'Select Employees',
                                style: TextStyle(fontSize: 20),
                              ),
                              buttonText: Text('Select Employees'),
                              searchable: true,
                              buttonIcon: Icon(Icons.group),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.indigo,
                                  width: 1,
                                ),
                              ),
                              chipDisplay: MultiSelectChipDisplay.none(),
                              onConfirm: (values) {
                                setState(() {
                                  _selectedEmployees =
                                      values.cast<Map<String, dynamic>>();
                                  // Auto-fill number of workers based on selected employees
                                  _updateWorkerCount();
                                });
                              },
                            ),
                            if (_selectedEmployees.isNotEmpty) ...[
                              SizedBox(height: 12),
                              Text(
                                '✅ Selected Employees:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: _selectedEmployees.map((e) {
                                  return Chip(
                                    label: Text(
                                      '${e['Eid'] ?? 'N/A'} - ${e['name'] ?? 'Unknown'}',
                                    ),
                                    backgroundColor: Colors.indigo.shade100,
                                    deleteIcon: Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedEmployees.remove(e);
                                        // Auto-update worker count when employee is removed
                                        _updateWorkerCount();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                            SizedBox(height: 24),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _submitSchedule,
                                icon: Icon(Icons.send, color: Colors.white),
                                label: Text(
                                  'Submit Schedule',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EmployeeNamesPage(),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.people, color: Colors.white),
                                label: Text(
                                  'Employee Names',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              '📅 All Schedules',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('schedule')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Text('No schedules found.');
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    final doc = snapshot.data!.docs[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final assignedEids = List<String>.from(
                                      data['assignedEmployees'] ?? [],
                                    );

                                    return FutureBuilder<QuerySnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('users')
                                          .where('Eid', whereIn: assignedEids)
                                          .get(),
                                      builder: (context, userSnapshot) {
                                        if (userSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        }

                                        final userDocs =
                                            userSnapshot.data?.docs ?? [];
                                        final assignedNames =
                                            userDocs.map((user) {
                                          try {
                                            final data = user.data()
                                                as Map<String, dynamic>;
                                            return '${data['Eid'] ?? 'N/A'} - ${data['name'] ?? 'Unknown'}';
                                          } catch (e) {
                                            print(
                                              'Error processing user data: $e',
                                            );
                                            return 'Error loading user';
                                          }
                                        }).join(', ');

                                        return Card(
                                          margin: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '📍 Branch: ${data['branchName']}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '📅 ${data['startDate']} to ${data['endDate']}',
                                                ),
                                                Text(
                                                  '🕒 ${data['startTime']} - ${data['endTime']}',
                                                ),
                                                Text(
                                                  '👥 Workers: ${data['numberOfWorkers']}',
                                                ),
                                                Text(
                                                  '⏱ Hours: ${data['totalHours']}',
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  '👷 Assigned Employees: $assignedNames',
                                                ),
                                                SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Status: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      data['status'] ??
                                                          'Not Set',
                                                      style: TextStyle(
                                                        color:
                                                            (data['status'] ==
                                                                    'done')
                                                                ? Colors.green
                                                                : Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    TextButton.icon(
                                                      icon: Icon(
                                                        Icons.check_circle,
                                                        color: Colors.green,
                                                      ),
                                                      label: Text(
                                                        'Done',
                                                        style: TextStyle(
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'schedule',
                                                            )
                                                            .doc(doc.id)
                                                            .update({
                                                          'status': 'done',
                                                        });
                                                      },
                                                    ),
                                                    SizedBox(width: 8),
                                                    TextButton.icon(
                                                      icon: Icon(
                                                        Icons.cancel,
                                                        color: Colors.red,
                                                      ),
                                                      label: Text(
                                                        'Not Done',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'schedule',
                                                            )
                                                            .doc(doc.id)
                                                            .update({
                                                          'status': 'not done',
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class EmployeeAttendancePage extends StatefulWidget {
  final String? userId;
  const EmployeeAttendancePage({Key? key, this.userId}) : super(key: key);

  @override
  _EmployeeAttendancePageState createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployeesWithAttendance();
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
            .where(
              (employee) =>
                  employee['name'].toLowerCase().contains(query) ||
                  employee['eid'].toLowerCase().contains(query) ||
                  (employee['email']?.toLowerCase().contains(query) ?? false) ||
                  (employee['gender']?.toLowerCase().contains(query) ??
                      false) ||
                  (employee['age']?.toString().toLowerCase().contains(query) ??
                      false) ||
                  (employee['phoneNo']?.toLowerCase().contains(query) ?? false),
            )
            .toList();
      }
    });
  }

  Future<void> _loadEmployeesWithAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is authenticated
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ User not authenticated');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('🚀 ADMIN: Loading employees with attendance...');

      // Get all users
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      print('📋 Found ${usersSnapshot.docs.length} users');

      List<Map<String, dynamic>> employeeList = [];

      for (var userDoc in usersSnapshot.docs) {
        String uid = userDoc.id;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        String name = userData['name']?.toString() ?? 'Unknown';
        String email = userData['email']?.toString() ?? 'No Email';
        String eid = userData['Eid']?.toString() ?? uid;
        String phoneNo = userData['mobile']?.toString() ?? 'No Phone';

        print('👤 User: $name (UID: $uid, EID: $eid)');

        // Try to find attendance data using multiple strategies
        int attendanceCount = 0;
        List<String> foundDates = [];
        int presentDays = 0;
        int halfDaysPresentCount = 0;
        int absentDays = 0;

        // Strategy 1: Try by Firebase UID
        try {
          QuerySnapshot att1 = await FirebaseFirestore.instance
              .collection('attendance')
              .doc(uid)
              .collection('dates')
              .get();

          if (att1.docs.isNotEmpty) {
            attendanceCount = att1.docs.length;
            foundDates = att1.docs.map((d) => d.id).toList();
            print('✅ Found ${attendanceCount} records by UID');

            // Process attendance records for status counting
            for (var doc in att1.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String status = _determineAttendanceStatus(data);

              switch (status.toLowerCase()) {
                case 'present':
                  presentDays++;
                  break;
                case 'halfday present':
                case 'half day present':
                case 'half-day present':
                  halfDaysPresentCount++;
                  break;
                default:
                  absentDays++;
              }
            }
          }
        } catch (e) {
          print('⚠️ UID strategy failed: $e');
        }

        // Strategy 2: Try by EID if no results
        if (attendanceCount == 0 && eid != uid) {
          try {
            QuerySnapshot att2 = await FirebaseFirestore.instance
                .collection('attendance')
                .doc(eid)
                .collection('dates')
                .get();

            if (att2.docs.isNotEmpty) {
              attendanceCount = att2.docs.length;
              foundDates = att2.docs.map((d) => d.id).toList();
              print('✅ Found ${attendanceCount} records by EID');

              // Process attendance records for status counting
              for (var doc in att2.docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String status = _determineAttendanceStatus(data);

                switch (status.toLowerCase()) {
                  case 'present':
                    presentDays++;
                    break;
                  case 'halfday present':
                  case 'half day present':
                  case 'half-day present':
                    halfDaysPresentCount++;
                    break;
                  default:
                    absentDays++;
                }
              }
            }
          } catch (e) {
            print('⚠️ EID strategy failed: $e');
          }
        }

        // Strategy 3: Check all attendance documents if still no results
        if (attendanceCount == 0) {
          try {
            QuerySnapshot allAtt =
                await FirebaseFirestore.instance.collection('attendance').get();

            print('📋 Checking ${allAtt.docs.length} attendance documents...');

            for (var doc in allAtt.docs) {
              if (doc.id == uid || doc.id == eid) {
                QuerySnapshot dates =
                    await doc.reference.collection('dates').get();
                attendanceCount = dates.docs.length;
                foundDates = dates.docs.map((d) => d.id).toList();
                print(
                    '✅ Found ${attendanceCount} records in document ${doc.id}');

                // Process attendance records for status counting
                for (var dateDoc in dates.docs) {
                  Map<String, dynamic> data =
                      dateDoc.data() as Map<String, dynamic>;
                  String status = _determineAttendanceStatus(data);

                  switch (status.toLowerCase()) {
                    case 'present':
                      presentDays++;
                      break;
                    case 'halfday present':
                    case 'half day present':
                    case 'half-day present':
                      halfDaysPresentCount++;
                      break;
                    default:
                      absentDays++;
                  }
                }
                break;
              }
            }
          } catch (e) {
            print('⚠️ Global search failed: $e');
          }
        }

        employeeList.add({
          'name': name,
          'email': email,
          'eid': eid,
          'uid': uid,
          'phoneNo': phoneNo,
          'attendanceCount': attendanceCount,
          'recentDates': foundDates.take(5).toList(),
          'presentDays': presentDays,
          'halfDaysPresentCount': halfDaysPresentCount,
          'absentDays': absentDays,
          'totalDays': attendanceCount,
        });
      }

      setState(() {
        _employees = employeeList;
        _filteredEmployees = employeeList;
        _isLoading = false;
      });

      print('🎉 Loaded ${employeeList.length} employees successfully!');
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _employees = [];
        _filteredEmployees = [];
        _isLoading = false;
      });
    }
  }

  // Helper method to determine attendance status
  String _determineAttendanceStatus(Map<String, dynamic> attendanceData) {
    // Strategy 1: Check explicit attendance_status field
    if (attendanceData.containsKey('attendance_status')) {
      String status = attendanceData['attendance_status']?.toString() ?? '';
      if (status.isNotEmpty) return status;
    }

    // Strategy 2: Check status field and infer from check-in/out
    if (attendanceData.containsKey('status')) {
      String status = attendanceData['status']?.toString() ?? '';
      String checkOut = attendanceData['checkOutTime']?.toString() ?? '';

      if (status == 'checked-in' && checkOut.isEmpty) {
        return 'present'; // Currently checked in
      } else if (status == 'checked-out') {
        // Try to calculate from time worked
        String formattedTime =
            attendanceData['formattedTime']?.toString() ?? '';
        if (formattedTime.isNotEmpty) {
          return _calculateStatusFromFormattedTime(formattedTime);
        }
        return 'present'; // Default for checked out users
      }
    }

    // Strategy 3: If has check-in time, assume present
    String checkIn = attendanceData['checkInTime']?.toString() ?? '';
    if (checkIn.isNotEmpty && checkIn != 'Not recorded') {
      return 'present';
    }

    // Strategy 4: Default to absent
    return 'absent';
  }

  // Helper method to calculate attendance status from formatted time
  String _calculateStatusFromFormattedTime(String formattedTime) {
    try {
      // Extract hours from "8 Hours 30 Minutes" format
      RegExp hoursRegex = RegExp(r'(\d+)\s*Hours?');
      RegExp minutesRegex = RegExp(r'(\d+)\s*Minutes?');

      int hours = 0;
      int minutes = 0;

      var hoursMatch = hoursRegex.firstMatch(formattedTime);
      var minutesMatch = minutesRegex.firstMatch(formattedTime);

      if (hoursMatch != null) {
        hours = int.parse(hoursMatch.group(1)!);
      }
      if (minutesMatch != null) {
        minutes = int.parse(minutesMatch.group(1)!);
      }

      double totalHours = hours + (minutes / 60.0);

      // Standard working day logic
      if (totalHours >= 8.0) {
        return 'present';
      } else if (totalHours >= 4.0) {
        return 'halfday present';
      } else {
        return 'absent';
      }
    } catch (e) {
      print('Error calculating status from formatted time: $e');
      return 'present'; // Default to present if we can't parse
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total statistics
    int totalPresent =
        _employees.fold(0, (sum, emp) => sum + (emp['presentDays'] as int));
    int totalHalfDay = _employees.fold(
        0, (sum, emp) => sum + (emp['halfDaysPresentCount'] as int));
    int totalAbsent =
        _employees.fold(0, (sum, emp) => sum + (emp['absentDays'] as int));
    int totalEmployees = _employees.length;

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Statistics cards
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Employees',
                    totalEmployees.toString(),
                    Colors.blue,
                    Icons.people,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Present',
                    totalPresent.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Half Day',
                    totalHalfDay.toString(),
                    Colors.orange,
                    Icons.schedule,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Absent',
                    totalAbsent.toString(),
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
          ),

          // Search bar with Refresh button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadEmployeesWithAttendance,
                  tooltip: 'Refresh',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(12),
                  ),
                ),
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
                            Icon(Icons.info, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No employees found',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEmployeesWithAttendance,
                        child: ListView.builder(
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = _filteredEmployees[index];
                            return _buildEmployeeCard(employee);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEmployeeDates(employee),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF2196F3),
                    child: Text(
                      employee['name'].toString().isNotEmpty
                          ? employee['name'].toString()[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${employee['eid']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          employee['email'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Attendance Records',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${employee['attendanceCount']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAttendanceChip(
                      'Present: ${employee['presentDays']}',
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildAttendanceChip(
                      'Half Day: ${employee['halfDaysPresentCount']}',
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildAttendanceChip(
                      'Absent: ${employee['absentDays']}',
                      Colors.red,
                    ),
                  ),
                ],
              ),
              if (employee['recentDates'].isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Recent Dates: ${employee['recentDates'].join(', ')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to employee dates page (Level 1)
  void _navigateToEmployeeDates(Map<String, dynamic> employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDatesPage(employee: employee),
      ),
    );
  }

  Widget _buildAttendanceChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// =================== DRILL-DOWN PAGES ===================

// Level 1: Employee Dates Page - Shows all dates with currentDate field
class EmployeeDatesPage extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EmployeeDatesPage({Key? key, required this.employee}) : super(key: key);

  @override
  _EmployeeDatesPageState createState() => _EmployeeDatesPageState();
}

class _EmployeeDatesPageState extends State<EmployeeDatesPage> {
  List<Map<String, dynamic>> _attendanceDates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceDates();
  }

  Future<void> _loadAttendanceDates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Loading attendance dates for ${widget.employee['name']}...');

      String uid = widget.employee['uid'];
      String eid = widget.employee['eid'];

      List<Map<String, dynamic>> datesList = [];

      // Strategy 1: Try by Firebase UID
      try {
        QuerySnapshot datesSnapshot = await FirebaseFirestore.instance
            .collection('attendance')
            .doc(uid)
            .collection('dates')
            .get();

        if (datesSnapshot.docs.isNotEmpty) {
          print('✅ Found ${datesSnapshot.docs.length} dates by UID');
          for (var doc in datesSnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            datesList.add({
              'dateId': doc.id,
              'currentDate': data['currentDate'] ?? doc.id,
              'data': data,
              'attendanceUid': uid,
            });
          }
        }
      } catch (e) {
        print('⚠️ UID strategy failed: $e');
      }

      // Strategy 2: Try by EID if no results
      if (datesList.isEmpty && eid != uid) {
        try {
          QuerySnapshot datesSnapshot = await FirebaseFirestore.instance
              .collection('attendance')
              .doc(eid)
              .collection('dates')
              .get();

          if (datesSnapshot.docs.isNotEmpty) {
            print('✅ Found ${datesSnapshot.docs.length} dates by EID');
            for (var doc in datesSnapshot.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              datesList.add({
                'dateId': doc.id,
                'currentDate': data['currentDate'] ?? doc.id,
                'data': data,
                'attendanceUid': eid,
              });
            }
          }
        } catch (e) {
          print('⚠️ EID strategy failed: $e');
        }
      }

      // Sort by date
      datesList.sort((a, b) {
        String dateA = a['currentDate'].toString();
        String dateB = b['currentDate'].toString();
        return dateB.compareTo(dateA); // Latest first
      });

      setState(() {
        _attendanceDates = datesList;
        _isLoading = false;
      });

      print('🎉 Loaded ${datesList.length} attendance dates!');
    } catch (e) {
      print('❌ Error loading attendance dates: $e');
      setState(() {
        _attendanceDates = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          '${widget.employee['name']} - Attendance Dates',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2196F3),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAttendanceDates,
          ),
        ],
      ),
      body: Column(
        children: [
          // Employee info header
          Container(
            width: double.infinity,
            color: Color(0xFF2196F3),
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFF2196F3),
                      radius: 30,
                      child: Text(
                        widget.employee['name'].toString().isNotEmpty
                            ? widget.employee['name']
                                .toString()[0]
                                .toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.employee['name'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Employee ID: ${widget.employee['eid']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            widget.employee['email'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Total Records',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${widget.employee['attendanceCount']}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Date cards list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _attendanceDates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No attendance dates found',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAttendanceDates,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _attendanceDates.length,
                          itemBuilder: (context, index) {
                            final attendance = _attendanceDates[index];
                            return _buildDateCard(attendance);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(Map<String, dynamic> attendance) {
    String currentDate = attendance['currentDate'].toString();
    Map<String, dynamic> data = attendance['data'];

    // Get status and basic info
    String status = _determineAttendanceStatus(data);
    String checkIn = data['checkInTime']?.toString() ?? 'Not recorded';
    String checkOut = data['checkOutTime']?.toString() ?? 'Not recorded';

    // Get color based on status
    Color statusColor = _getStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDateDetails(attendance),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: $currentDate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeChip('Check In', checkIn, Colors.green),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildTimeChip('Check Out', checkOut, Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, String time, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _determineAttendanceStatus(Map<String, dynamic> data) {
    if (data.containsKey('attendance_status')) {
      String status = data['attendance_status']?.toString() ?? '';
      if (status.isNotEmpty) return status;
    }

    if (data.containsKey('status')) {
      String status = data['status']?.toString() ?? '';
      String checkOut = data['checkOutTime']?.toString() ?? '';

      if (status == 'checked-in' && checkOut.isEmpty) {
        return 'Present';
      } else if (status == 'checked-out') {
        return 'Present';
      }
    }

    String checkIn = data['checkInTime']?.toString() ?? '';
    if (checkIn.isNotEmpty && checkIn != 'Not recorded') {
      return 'Present';
    }

    return 'Absent';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'halfday present':
      case 'half day present':
      case 'half-day present':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'halfday present':
      case 'half day present':
      case 'half-day present':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }

  // Navigate to date details page (Level 2)
  void _navigateToDateDetails(Map<String, dynamic> attendance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DateDetailsPage(
          employee: widget.employee,
          attendance: attendance,
        ),
      ),
    );
  }
}

// Level 2: Date Details Page - Shows detailed attendance info
class DateDetailsPage extends StatefulWidget {
  final Map<String, dynamic> employee;
  final Map<String, dynamic> attendance;

  const DateDetailsPage({
    Key? key,
    required this.employee,
    required this.attendance,
  }) : super(key: key);

  @override
  _DateDetailsPageState createState() => _DateDetailsPageState();
}

class _DateDetailsPageState extends State<DateDetailsPage> {
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = widget.attendance['data'];
    String currentDate = widget.attendance['currentDate'].toString();

    // Extract the required fields
    String eid = data['Eid']?.toString() ?? widget.employee['eid'].toString();
    String name =
        data['name']?.toString() ?? widget.employee['name'].toString();
    String attendanceStatus = data['attendance_status']?.toString() ??
        _determineAttendanceStatus(data);
    String checkInTime = data['checkInTime']?.toString() ?? 'Not recorded';
    String checkOutTime = data['checkOutTime']?.toString() ?? 'Not recorded';
    String formattedTime =
        data['formattedTime']?.toString() ?? 'Not calculated';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Attendance Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2196F3),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with date info
            Container(
              width: double.infinity,
              color: Color(0xFF2196F3),
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: Color(0xFF2196F3),
                      ),
                      SizedBox(height: 8),
                      Text(
                        currentDate,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Attendance Details',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Required fields display
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailCard(
                    'Employee ID',
                    eid,
                    Icons.badge,
                    Colors.blue,
                  ),
                  SizedBox(height: 12),
                  _buildDetailCard(
                    'Employee Name',
                    name,
                    Icons.person,
                    Colors.green,
                  ),
                  SizedBox(height: 12),
                  _buildDetailCard(
                    'Attendance Status',
                    attendanceStatus,
                    _getStatusIcon(attendanceStatus),
                    _getStatusColor(attendanceStatus),
                  ),
                  SizedBox(height: 12),
                  _buildDetailCard(
                    'Check In Time',
                    checkInTime,
                    Icons.login,
                    Colors.green,
                  ),
                  SizedBox(height: 12),
                  _buildDetailCard(
                    'Check Out Time',
                    checkOutTime,
                    Icons.logout,
                    Colors.red,
                  ),
                  SizedBox(height: 12),
                  _buildDetailCard(
                    'Total Time Worked',
                    formattedTime,
                    Icons.access_time,
                    Colors.purple,
                  ),
                ],
              ),
            ),

            // Additional information if available
            if (data.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.all(16),
                child: Card(
                  child: ExpansionTile(
                    title: Text(
                      'Additional Data',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    leading: Icon(Icons.info_outline),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: data.entries.map((entry) {
                            if ([
                              'Eid',
                              'name',
                              'attendance_status',
                              'checkInTime',
                              'checkOutTime',
                              'formattedTime'
                            ].contains(entry.key)) {
                              return SizedBox.shrink();
                            }
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      entry.value.toString(),
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _determineAttendanceStatus(Map<String, dynamic> data) {
    if (data.containsKey('attendance_status')) {
      String status = data['attendance_status']?.toString() ?? '';
      if (status.isNotEmpty) return status;
    }

    if (data.containsKey('status')) {
      String status = data['status']?.toString() ?? '';
      String checkOut = data['checkOutTime']?.toString() ?? '';

      if (status == 'checked-in' && checkOut.isEmpty) {
        return 'Present';
      } else if (status == 'checked-out') {
        return 'Present';
      }
    }

    String checkIn = data['checkInTime']?.toString() ?? '';
    if (checkIn.isNotEmpty && checkIn != 'Not recorded') {
      return 'Present';
    }

    return 'Absent';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'halfday present':
      case 'half day present':
      case 'half-day present':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'halfday present':
      case 'half day present':
      case 'half-day present':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }
}

// =================== END DRILL-DOWN PAGES ===================

// TrackingScreen - Live Location tracking with Google Maps
class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  List<Map<String, dynamic>> _liveLocations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLiveLocations();
  }

  Future<void> _loadLiveLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📍 Loading live locations from Firestore...');

      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('live_locations').get();

      List<Map<String, dynamic>> locations = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Ensure we have required fields
        if (data.containsKey('name') &&
            data.containsKey('Eid') &&
            data.containsKey('latitude') &&
            data.containsKey('longitude')) {
          locations.add({
            'id': doc.id,
            'name': data['name']?.toString() ?? 'Unknown',
            'Eid': data['Eid']?.toString() ?? 'N/A',
            'latitude': _parseDouble(data['latitude']),
            'longitude': _parseDouble(data['longitude']),
            'timestamp': data['timestamp'],
            'allData': data, // Store all data for debugging
          });
        }
      }

      print('✅ Loaded ${locations.length} live locations');

      setState(() {
        _liveLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading live locations: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading live locations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  List<Map<String, dynamic>> get _filteredLocations {
    if (_searchQuery.isEmpty) return _liveLocations;

    return _liveLocations.where((location) {
      String name = location['name'].toString().toLowerCase();
      String eid = location['Eid'].toString().toLowerCase();
      String query = _searchQuery.toLowerCase();

      return name.contains(query) || eid.contains(query);
    }).toList();
  }

  void _navigateToMap(Map<String, dynamic> location) async {
    double lat = location['latitude'];
    double lng = location['longitude'];

    // Try different URL schemes for opening Google Maps
    List<String> urls = [
      'google.navigation:q=$lat,$lng', // Google Maps navigation
      'comgooglemaps://?q=$lat,$lng', // Google Maps app
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng', // Web fallback
    ];

    bool launched = false;

    for (String url in urls) {
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        print('Failed to launch $url: $e');
      }
    }

    if (!launched) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Google Maps'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Search Bar with Refresh Button
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or Employee ID...',
                      prefixIcon: Icon(Icons.search, color: Colors.indigo),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.indigo.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.indigo.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.indigo, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.indigo),
                  onPressed: _loadLiveLocations,
                  tooltip: 'Refresh Locations',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.indigo),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading live locations...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredLocations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No live locations found'
                                  : 'No locations match your search',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Live locations will appear here when available'
                                  : 'Try searching with different keywords',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLiveLocations,
                        color: Colors.indigo,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredLocations.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> location =
                                _filteredLocations[index];
                            return _buildLocationCard(location);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToMap(location),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with location icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.indigo.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.person_pin_circle,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              SizedBox(width: 16),

              // Employee details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.badge,
                          size: 16,
                          color: Colors.indigo.shade400,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ID: ${location['Eid']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Lat: ${location['latitude'].toStringAsFixed(6)}, '
                            'Lng: ${location['longitude'].toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Navigation arrow
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.indigo,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Page
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _decodeProfileImage() {
    if (userData["profilePicBinary"] != null &&
        userData["profilePicBinary"] is String &&
        (userData["profilePicBinary"] as String).isNotEmpty) {
      try {
        _profileImageBytes = base64Decode(userData["profilePicBinary"]);
        setState(() {});
      } catch (e) {
        print("Error decoding profile image: $e");
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Not available";

    if (timestamp is Timestamp) {
      // Firestore Timestamp
      DateTime dateTime = timestamp.toDate();
      return dateTime.toString();
    } else if (timestamp is String) {
      // Already a string
      return timestamp;
    } else {
      // Try to convert to string
      return timestamp.toString();
    }
  }

  String _getStringValue(dynamic value) {
    if (value == null) return "";
    if (value is String) return value;
    return value.toString();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      print("📥 Fetching admin profile data for: ${user.uid}");

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Admins')
          .doc(user.uid)
          .get()
          .timeout(Duration(seconds: 10));

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print("✅ Admin profile data loaded successfully");

        setState(() {
          userData = data;
          isLoading = false;
        });

        // Decode profile image if available
        _decodeProfileImage();
      } else {
        print("❌ Admin document not found for user: ${user.uid}");
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin profile not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Error loading admin profile: $e");
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Create update data, excluding sensitive fields that shouldn't be updated
          Map<String, dynamic> updateData = Map<String, dynamic>.from(userData);

          // Preserve these fields (don't update them via form)
          updateData
              .remove('Password'); // Don't update password through profile
          updateData.remove('uid'); // UID should not be changed
          updateData.remove('timestamp'); // Timestamp should not be changed

          // Preserve profilePicBinary if it exists (we don't update it through this form)
          // If you want to allow updating profile pic, you'd need to add image picker functionality

          // Ensure both Email and email fields are updated
          if (updateData.containsKey('Email')) {
            updateData['email'] = updateData['Email'];
          } else if (updateData.containsKey('email')) {
            updateData['Email'] = updateData['email'];
          }

          await FirebaseFirestore.instance
              .collection('Admins')
              .doc(user.uid)
              .update(updateData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Profile updated successfully"),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print("❌ Error updating admin profile: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error updating profile: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading admin profile...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.indigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!)
                          : null,
                      child: _profileImageBytes == null
                          ? Icon(
                              Icons.admin_panel_settings,
                              size: 50,
                              color: Colors.blueAccent,
                            )
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "${userData["FirstName"] ?? ""} ${userData["LastName"] ?? ""}"
                          .trim(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Administrator",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    if (userData["Email"] != null ||
                        userData["email"] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        userData["Email"] ?? userData["email"] ?? "",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Profile Form
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Profile Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 20),
                    // First Name
                    TextFormField(
                      initialValue: _getStringValue(userData["FirstName"]),
                      decoration: InputDecoration(
                        labelText: "First Name",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => userData["FirstName"] = value,
                      validator: (value) =>
                          value!.isEmpty ? "Please enter a first name" : null,
                    ),
                    SizedBox(height: 16),
                    // Last Name
                    TextFormField(
                      initialValue: _getStringValue(userData["LastName"]),
                      decoration: InputDecoration(
                        labelText: "Last Name",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => userData["LastName"] = value,
                      validator: (value) =>
                          value!.isEmpty ? "Please enter a last name" : null,
                    ),
                    SizedBox(height: 16),
                    // Email (using Email field first, fallback to email)
                    TextFormField(
                      initialValue: _getStringValue(
                          userData["Email"] ?? userData["email"]),
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        userData["Email"] = value;
                        userData["email"] = value; // Update both fields
                      },
                      validator: (value) =>
                          value!.isEmpty ? "Please enter an email" : null,
                    ),
                    SizedBox(height: 16),
                    // Phone Number
                    TextFormField(
                      initialValue: _getStringValue(userData["PhoneNumber"]),
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => userData["PhoneNumber"] = value,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    // Age
                    TextFormField(
                      initialValue: _getStringValue(userData["Age"]),
                      decoration: InputDecoration(
                        labelText: "Age",
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => userData["Age"] = value,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    // Date of Birth
                    TextFormField(
                      initialValue: _getStringValue(userData["DateOfBirth"]),
                      decoration: InputDecoration(
                        labelText: "Date of Birth",
                        prefixIcon: Icon(Icons.cake),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => userData["DateOfBirth"] = value,
                      readOnly: true,
                    ),
                    SizedBox(height: 16),
                    // Gender
                    TextFormField(
                      initialValue: _getStringValue(userData["Gender"]),
                      decoration: InputDecoration(
                        labelText: "Gender",
                        prefixIcon: Icon(Icons.people),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => userData["Gender"] = value,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: Icon(Icons.save),
                        label: Text("Save Changes"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Edit Profile Page
class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfilePage({Key? key, this.userData}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    userData = widget.userData ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.blue[100],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: userData["name"],
                decoration: InputDecoration(labelText: "Name"),
                onChanged: (value) => userData["name"] = value,
              ),
              TextFormField(
                initialValue: userData["email"],
                decoration: InputDecoration(labelText: "Email"),
                onChanged: (value) => userData["email"] = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Active Users Page - simplified
class ActiveUsersPage extends StatefulWidget {
  @override
  _ActiveUsersPageState createState() => _ActiveUsersPageState();
}

class _ActiveUsersPageState extends State<ActiveUsersPage> {
  List<Map<String, dynamic>> _activeUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveUsers();
  }

  Future<void> _loadActiveUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is authenticated
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ User not authenticated for active users');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String todayDate = _getTodayDate();

      // Get all users
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> activeUsers = [];

      for (var userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String uid = userDoc.id;
        String eid = userData['Eid'] ?? 'N/A';

        // Check if user has attendance for today
        bool hasTodayAttendance =
            await _checkTodayAttendance(uid, eid, todayDate);

        if (hasTodayAttendance) {
          // Get attendance details for today
          Map<String, dynamic> attendanceData =
              await _getTodayAttendanceDetails(uid, eid, todayDate);

          // Debug print to check user data fields
          print('🔍 User data for $uid: ${userData.keys.toList()}');
          print('🔍 Gender: ${userData['gender']}, Age: ${userData['age']}');

          // Try alternative field names if main ones don't exist
          String gender = userData['gender'] ??
              userData['Gender'] ??
              userData['GENDER'] ??
              'Not specified';

          String age = userData['age']?.toString() ??
              userData['Age']?.toString() ??
              userData['AGE']?.toString() ??
              'Not specified';

          activeUsers.add({
            'uid': uid,
            'eid': eid,
            'name': userData['name'] ?? 'Unknown',
            'email': userData['email'] ?? 'No email',
            'phoneNo': userData['mobile'] ?? 'No phone',
            'gender': gender,
            'age': age,
            'attendanceData': attendanceData,
          });
        }
      }

      setState(() {
        _activeUsers = activeUsers;
        _isLoading = false;
      });

      print(
          '📊 Found ${activeUsers.length} active users for today ($todayDate)');
    } catch (e) {
      print('❌ Error loading active users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTodayDate() {
    DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _checkTodayAttendance(
      String uid, String eid, String todayDate) async {
    try {
      // Strategy 1: Check by UID
      DocumentSnapshot uidDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(uid)
          .collection('dates')
          .doc(todayDate)
          .get();

      if (uidDoc.exists) {
        return true;
      }

      // Strategy 2: Check by EID
      DocumentSnapshot eidDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(eid)
          .collection('dates')
          .doc(todayDate)
          .get();

      return eidDoc.exists;
    } catch (e) {
      print('Error checking attendance for $uid/$eid: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _getTodayAttendanceDetails(
      String uid, String eid, String todayDate) async {
    try {
      // Try to get attendance data by UID first
      DocumentSnapshot uidDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(uid)
          .collection('dates')
          .doc(todayDate)
          .get();

      if (uidDoc.exists) {
        return uidDoc.data() as Map<String, dynamic>;
      }

      // Try to get attendance data by EID
      DocumentSnapshot eidDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(eid)
          .collection('dates')
          .doc(todayDate)
          .get();

      if (eidDoc.exists) {
        return eidDoc.data() as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      print('Error getting attendance details for $uid/$eid: $e');
      return {};
    }
  }

  String _getAttendanceStatus(Map<String, dynamic> attendanceData) {
    if (attendanceData.isEmpty) return 'Unknown';

    // Check explicit status
    if (attendanceData.containsKey('attendance_status')) {
      return attendanceData['attendance_status'].toString();
    }

    // Check general status
    String status = attendanceData['status']?.toString() ?? '';
    String checkOut = attendanceData['checkOutTime']?.toString() ?? '';

    if (status == 'checked-in' && checkOut.isEmpty) {
      return 'Currently Working';
    } else if (status == 'checked-out') {
      return 'Completed Work';
    }

    return 'Present';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Active Users',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadActiveUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header with stats
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.green[700], size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Users Today',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'Employees who marked attendance today (${_getTodayDate()})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_activeUsers.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 16),
                        Text('Loading active users...'),
                      ],
                    ),
                  )
                : _activeUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Active Users Today',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'No employees have marked attendance today',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadActiveUsers,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _activeUsers.length,
                          itemBuilder: (context, index) {
                            final user = _activeUsers[index];
                            final attendanceData =
                                user['attendanceData'] as Map<String, dynamic>;
                            final attendanceStatus =
                                _getAttendanceStatus(attendanceData);

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with name and status
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.green,
                                          radius: 24,
                                          child: Text(
                                            user['name'][0].toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'],
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'ID: ${user['eid']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.green[300]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: Colors.green[700],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                attendanceStatus,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 16),

                                    // Employee details
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[200]!),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildDetailRow(Icons.email, 'Email',
                                              user['email']),
                                          _buildDetailRow(Icons.phone, 'Phone',
                                              user['phoneNo']),
                                          _buildDetailRow(
                                              Icons.person,
                                              'Gender',
                                              user['gender'] ??
                                                  'Not specified'),
                                          _buildDetailRow(
                                              Icons.cake,
                                              'Age',
                                              user['age']?.toString() ??
                                                  'Not specified'),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 12),

                                    // Attendance details
                                    if (attendanceData.isNotEmpty) ...[
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.green[200]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.access_time,
                                                    color: Colors.green[700],
                                                    size: 18),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Today\'s Attendance',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildAttendanceDetail(
                                                    'Check In',
                                                    attendanceData[
                                                                'checkInTime']
                                                            ?.toString() ??
                                                        'Not recorded',
                                                    Icons.login,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: _buildAttendanceDetail(
                                                    'Check Out',
                                                    attendanceData['checkOutTime']
                                                                ?.toString()
                                                                .isEmpty ==
                                                            true
                                                        ? 'Still working'
                                                        : attendanceData[
                                                                    'checkOutTime']
                                                                ?.toString() ??
                                                            'Not recorded',
                                                    Icons.logout,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (attendanceData['formattedTime']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true) ...[
                                              SizedBox(height: 8),
                                              _buildAttendanceDetail(
                                                'Total Work Time',
                                                attendanceData['formattedTime']
                                                    .toString(),
                                                Icons.timer,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDetail(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.green[600]),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Inactive Users Page - simplified
class InactiveUsersPage extends StatefulWidget {
  @override
  _InactiveUsersPageState createState() => _InactiveUsersPageState();
}

class _InactiveUsersPageState extends State<InactiveUsersPage> {
  List<Map<String, dynamic>> _inactiveUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInactiveUsers();
  }

  Future<void> _loadInactiveUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is authenticated
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ User not authenticated for inactive users');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String todayDate = _getTodayDate();

      // Get all users
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> inactiveUsers = [];

      for (var userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String uid = userDoc.id;
        String eid = userData['Eid'] ?? 'N/A';

        // Check if user has attendance for today
        bool hasTodayAttendance =
            await _checkTodayAttendance(uid, eid, todayDate);

        if (!hasTodayAttendance) {
          // Debug print to check user data fields
          print('🔍 Inactive user data for $uid: ${userData.keys.toList()}');
          print('🔍 Gender: ${userData['gender']}, Age: ${userData['age']}');

          // Try alternative field names if main ones don't exist
          String gender = userData['gender'] ??
              userData['Gender'] ??
              userData['GENDER'] ??
              'Not specified';

          String age = userData['age']?.toString() ??
              userData['Age']?.toString() ??
              userData['AGE']?.toString() ??
              'Not specified';

          inactiveUsers.add({
            'uid': uid,
            'eid': eid,
            'name': userData['name'] ?? 'Unknown',
            'email': userData['email'] ?? 'No email',
            'phoneNo': userData['mobile'] ?? 'No phone',
            'gender': gender,
            'age': age,
          });
        }
      }

      setState(() {
        _inactiveUsers = inactiveUsers;
        _isLoading = false;
      });

      print(
          '📊 Found ${inactiveUsers.length} inactive users for today ($todayDate)');
    } catch (e) {
      print('❌ Error loading inactive users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTodayDate() {
    DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _checkTodayAttendance(
      String uid, String eid, String todayDate) async {
    try {
      // Strategy 1: Check by UID
      DocumentSnapshot uidDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(uid)
          .collection('dates')
          .doc(todayDate)
          .get();

      if (uidDoc.exists) {
        return true;
      }

      // Strategy 2: Check by EID
      DocumentSnapshot eidDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(eid)
          .collection('dates')
          .doc(todayDate)
          .get();

      return eidDoc.exists;
    } catch (e) {
      print('Error checking attendance for $uid/$eid: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inactive Users',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInactiveUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header with stats
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.red[50],
            child: Row(
              children: [
                Icon(Icons.people_outline, color: Colors.red[700], size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inactive Users Today',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      Text(
                        'Employees who haven\'t marked attendance today (${_getTodayDate()})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_inactiveUsers.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.red),
                        SizedBox(height: 16),
                        Text('Loading inactive users...'),
                      ],
                    ),
                  )
                : _inactiveUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'All Users Are Active!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'All employees have marked attendance today',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInactiveUsers,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _inactiveUsers.length,
                          itemBuilder: (context, index) {
                            final user = _inactiveUsers[index];

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with name and status
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.red,
                                          radius: 24,
                                          child: Text(
                                            user['name'][0].toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'],
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'ID: ${user['eid']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.red[300]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.cancel,
                                                size: 16,
                                                color: Colors.red[700],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Absent',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 16),

                                    // Employee details
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[200]!),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildDetailRow(Icons.email, 'Email',
                                              user['email']),
                                          _buildDetailRow(Icons.phone, 'Phone',
                                              user['phoneNo']),
                                          _buildDetailRow(
                                              Icons.person,
                                              'Gender',
                                              user['gender'] ??
                                                  'Not specified'),
                                          _buildDetailRow(
                                              Icons.cake,
                                              'Age',
                                              user['age']?.toString() ??
                                                  'Not specified'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Live Location Map Page - Google Maps integration
class LiveLocationMapPage extends StatefulWidget {
  final Map<String, dynamic> location;

  const LiveLocationMapPage({Key? key, required this.location})
      : super(key: key);

  @override
  _LiveLocationMapPageState createState() => _LiveLocationMapPageState();
}

class _LiveLocationMapPageState extends State<LiveLocationMapPage> {
  late gmaps.GoogleMapController _mapController;
  late gmaps.LatLng _userLocation;
  late Set<gmaps.Marker> _markers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    try {
      double latitude = widget.location['latitude'];
      double longitude = widget.location['longitude'];

      if (latitude == 0.0 && longitude == 0.0) {
        throw Exception('Invalid coordinates');
      }

      _userLocation = gmaps.LatLng(latitude, longitude);

      _markers = {
        gmaps.Marker(
          markerId: gmaps.MarkerId(widget.location['Eid']),
          position: _userLocation,
          infoWindow: gmaps.InfoWindow(
            title: widget.location['name'],
            snippet: 'Employee ID: ${widget.location['Eid']}',
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueRed),
        ),
      };

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error initializing map: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading location: Invalid coordinates'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapCreated(gmaps.GoogleMapController controller) {
    _mapController = controller;

    // Animate to user location with some delay to ensure map is ready
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _mapController.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: _userLocation,
              zoom: 16.0,
            ),
          ),
        );
      }
    });
  }

  void _centerOnUser() {
    _mapController.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: _userLocation,
          zoom: 18.0,
        ),
      ),
    );
  }

  void _openInGoogleMaps() async {
    double lat = widget.location['latitude'];
    double lng = widget.location['longitude'];

    // Try different URL schemes for opening Google Maps
    List<String> urls = [
      'google.navigation:q=$lat,$lng', // Google Maps navigation
      'comgooglemaps://?q=$lat,$lng', // Google Maps app
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng', // Web fallback
    ];

    bool launched = false;

    for (String url in urls) {
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        print('Failed to launch $url: $e');
      }
    }

    if (!launched) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Google Maps'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.location['name'],
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new, color: Colors.white),
            onPressed: _openInGoogleMaps,
            tooltip: 'Open in Google Maps',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading map...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Employee info card
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(12),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.indigo, Colors.indigo.shade300],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.location['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Employee ID: ${widget.location['Eid']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Lat: ${widget.location['latitude'].toStringAsFixed(6)}, '
                                  'Lng: ${widget.location['longitude'].toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.green[700],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Live',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Google Map
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: gmaps.GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: gmaps.CameraPosition(
                          target: _userLocation,
                          zoom: 16.0,
                        ),
                        markers: _markers,
                        mapType: gmaps.MapType.normal,
                        compassEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _centerOnUser,
                          icon: Icon(Icons.my_location, color: Colors.white),
                          label: Text(
                            'Center Location',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openInGoogleMaps,
                          icon: Icon(Icons.open_in_new, color: Colors.white),
                          label: Text(
                            'Open in Maps',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
