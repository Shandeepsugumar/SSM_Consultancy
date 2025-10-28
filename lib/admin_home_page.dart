import 'package:consultancy/admin_waiting_for_approval.dart';
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
import 'package:consultancy/admin_donepage.dart';
import 'package:consultancy/loginpage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:consultancy/admin_attendance_calendar_enhance.dart';
import 'package:consultancy/admin_comprehensive_attendance_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
        leading: _selectedIndex == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
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
                MaterialPageRoute(builder: (context) => UsersList()),
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

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("Admins")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        userData = doc.data() as Map<String, dynamic>;
        _profileImageUrl = userData!["profileImageUrl"];
        _profilePicBinary = userData!["profilePicBinary"];

        if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
          try {
            _profileImageBytes = base64Decode(_profilePicBinary!);
          } catch (e) {
            print("Error decoding base64: $e");
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _isLoading ? CircularProgressIndicator() : _buildProfileSection(),
          SizedBox(height: 10),
        ],
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
                await fetchUserName();
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

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchLatestSchedule(); // new
  }

  Future<void> _fetchLatestSchedule() async {
    final scheduleSnapshot = await FirebaseFirestore.instance
        .collection('schedule')
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    if (scheduleSnapshot.docs.isNotEmpty) {
      final scheduleData = scheduleSnapshot.docs.first.data();
      final List<dynamic> assignedUIDs =
          scheduleData['assignedEmployees'] ?? [];

      List<String> resolvedEmployeeNames = [];

      for (var uid in assignedUIDs) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data() as Map<String, dynamic>;
            resolvedEmployeeNames.add(
              '${data['Eid'] ?? 'N/A'} - ${data['name'] ?? 'Unknown'}',
            );
          } else {
            resolvedEmployeeNames.add('Unknown');
          }
        } catch (e) {
          print('Error fetching user data for uid $uid: $e');
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
      List<String> selectedUIDs =
          _selectedEmployees.map((e) => e['uid'].toString()).toList();

      try {
        await FirebaseFirestore.instance.collection('schedule').add({
          'startTime': _startTimeController.text,
          'endTime': _endTimeController.text,
          'startDate': _startDateController.text,
          'endDate': _endDateController.text,
          'branchName': _branchNameController.text,
          'numberOfWorkers': int.parse(_numWorkersController.text),
          'totalHours': _totalHoursController.text,
          'assignedEmployees': selectedUIDs,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Schedule Created Successfully')),
        );
        _fetchLatestSchedule();
        _formKey.currentState!.reset();
        _selectedEmployees.clear();
        setState(() {});
      } catch (e) {
        print("🔥 Firestore write failed: $e");
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
                              label: 'Number of Workers',
                              controller: _numWorkersController,
                              type: TextInputType.number,
                              icon: Icons.people,
                            ),
                            _buildTextField(
                              label: 'Total Work Hours',
                              controller: _totalHoursController,
                              type: TextInputType.number,
                              icon: Icons.timelapse,
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
                                      builder: (context) => DonePage(),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.done_all),
                                label: Text('View Done'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
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
                            SizedBox(height: 32),
                            // Employee Eids Display Section
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.badge,
                                        color: Colors.blue[700],
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'All Employee Eids',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
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
                                        return Text('No employees found.');
                                      }

                                      final employees = snapshot.data!.docs;
                                      return Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: employees.map((doc) {
                                          try {
                                            final data = doc.data()
                                                as Map<String, dynamic>;
                                            final eid = data['Eid'] ?? 'N/A';
                                            final name =
                                                data['name'] ?? 'Unknown';

                                            return Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.blue[300]!,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue[100]!,
                                                    blurRadius: 2,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    size: 16,
                                                    color: Colors.blue[600],
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '$eid - $name',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          } catch (e) {
                                            print(
                                              'Error processing employee data: $e',
                                            );
                                            return Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.red[300]!,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.error,
                                                    size: 16,
                                                    color: Colors.red[600],
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Error loading employee',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.red[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
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
                                    final assignedUids = List<String>.from(
                                      data['assignedEmployees'] ?? [],
                                    );

                                    return FutureBuilder<QuerySnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('users')
                                          .where(
                                            FieldPath.documentId,
                                            whereIn: assignedUids,
                                          )
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
                  (employee['role']?.toLowerCase().contains(query) ?? false) ||
                  (employee['department']?.toLowerCase().contains(query) ??
                      false) ||
                  (employee['phoneNumber']?.toLowerCase().contains(query) ??
                      false),
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
        String phoneNo = userData['phoneNo']?.toString() ?? 'No Phone';

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

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Employee Attendance',
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
            onPressed: _loadEmployeesWithAttendance,
          ),
        ],
      ),
      body: Column(
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

          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
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

// TrackingScreen - simplified version without location
class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location Tracking"),
        backgroundColor: Colors.blue[100],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              "Location Tracking",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Feature available in next update",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
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
                validator: (value) =>
                    value!.isEmpty ? "Please enter a name" : null,
              ),
              TextFormField(
                initialValue: userData["email"],
                decoration: InputDecoration(labelText: "Email"),
                onChanged: (value) => userData["email"] = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter an email" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text("Save Changes"),
              ),
            ],
          ),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Users'),
        backgroundColor: Colors.green[100],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              "Active Users",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Feature available in next update",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Inactive Users Page - simplified
class InactiveUsersPage extends StatefulWidget {
  @override
  _InactiveUsersPageState createState() => _InactiveUsersPageState();
}

class _InactiveUsersPageState extends State<InactiveUsersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inactive Users'),
        backgroundColor: Colors.red[100],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 100, color: Colors.red),
            SizedBox(height: 20),
            Text(
              "Inactive Users",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Feature available in next update",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// UsersList class for admin management
class UsersList extends StatefulWidget {
  @override
  _UsersListState createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  // Implementation here
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Users List')),
        body: Center(child: Text('Users List')));
  }
}
