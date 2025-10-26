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
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:consultancy/admin_donepage.dart';
import 'package:consultancy/loginpage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
    AdminComprehensiveAttendanceScreen(),
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
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(50),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
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
              _buildButton(context, "Active User", Icons.check_circle,
                  Colors.green, "/activeUsers"),
              _buildButton(context, "Inactive User", Icons.cancel, Colors.red,
                  "/inactiveUsers"),
              _buildButton(context, "Waiting for Approval", Icons.hourglass_top,
                  Colors.orange, "UserCard"), // Updated Route
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, IconData icon,
      Color color, String route) {
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
            )
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: color, size: 28),
          title: Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87)),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
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
            resolvedEmployeeNames
                .add('${data['Eid'] ?? 'N/A'} - ${data['name'] ?? 'Unknown'}');
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
              .map((e) => MultiSelectItem<Map<String, dynamic>>(
                  e, '${e['Eid']} - ${e['name']}'))
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('⚠️ Please fill all fields and select employees')),
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
          Text('$label: ',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          Expanded(
            child: Text(value),
          ),
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
                                    fontSize: 20, fontWeight: FontWeight.bold),
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
                              title: Text('Select Employees',
                                  style: TextStyle(fontSize: 20)),
                              buttonText: Text('Select Employees'),
                              searchable: true,
                              buttonIcon: Icon(Icons.group),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.indigo, width: 1),
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
                                        '${e['Eid'] ?? 'N/A'} - ${e['name'] ?? 'Unknown'}'),
                                    backgroundColor: Colors.indigo.shade100,
                                    deleteIcon:
                                        Icon(Icons.cancel, color: Colors.red),
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
                                label: Text('Submit Schedule',
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
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
                                        builder: (context) => DonePage()),
                                  );
                                },
                                icon: Icon(Icons.done_all),
                                label: Text('View Done'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
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
                                      Icon(Icons.badge,
                                          color: Colors.blue[700]),
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
                                            child: CircularProgressIndicator());
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
                                                  horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                    color: Colors.blue[300]!),
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
                                                'Error processing employee data: $e');
                                            return Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                    color: Colors.red[300]!),
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
                                  fontSize: 18, fontWeight: FontWeight.bold),
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
                                      child: CircularProgressIndicator());
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
                                        data['assignedEmployees'] ?? []);

                                    return FutureBuilder<QuerySnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('users')
                                          .where(FieldPath.documentId,
                                              whereIn: assignedUids)
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
                                                'Error processing user data: $e');
                                            return 'Error loading user';
                                          }
                                        }).join(', ');

                                        return Card(
                                          margin:
                                              EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    '📍 Branch: ${data['branchName']}',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                    '📅 ${data['startDate']} to ${data['endDate']}'),
                                                Text(
                                                    '🕒 ${data['startTime']} - ${data['endTime']}'),
                                                Text(
                                                    '👥 Workers: ${data['numberOfWorkers']}'),
                                                Text(
                                                    '⏱ Hours: ${data['totalHours']}'),
                                                SizedBox(height: 6),
                                                Text(
                                                    '👷 Assigned Employees: $assignedNames'),
                                                SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Status: ',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
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
                                                          color: Colors.green),
                                                      label: Text('Done',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .green)),
                                                      onPressed: () {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'schedule')
                                                            .doc(doc.id)
                                                            .update({
                                                          'status': 'done'
                                                        });
                                                      },
                                                    ),
                                                    SizedBox(width: 8),
                                                    TextButton.icon(
                                                      icon: Icon(Icons.cancel,
                                                          color: Colors.red),
                                                      label: Text('Not Done',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                      onPressed: () {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'schedule')
                                                            .doc(doc.id)
                                                            .update({
                                                          'status': 'not done'
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
  String _currentDate = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
            .where((employee) =>
                employee['name'].toLowerCase().contains(query) ||
                employee['eid'].toLowerCase().contains(query) ||
                employee['email'].toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadEmployeesWithAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading employees with attendance for date: $_currentDate');

      // Get all attendance documents - document IDs are the user IDs
      QuerySnapshot attendanceSnapshot =
          await FirebaseFirestore.instance.collection('attendance').get();

      print('Found ${attendanceSnapshot.docs.length} attendance documents');

      List<Map<String, dynamic>> employeeList = [];

      for (var doc in attendanceSnapshot.docs) {
        String userId = doc.id;

        try {
          // Get user details
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            String userName = userData['name'] ?? 'Unknown';
            String eid = userData['Eid'] ?? userId;
            String email = userData['email'] ?? 'N/A';

            // Get all attendance records for this employee
            QuerySnapshot dateSnapshot = await FirebaseFirestore.instance
                .collection('attendance')
                .doc(userId)
                .collection('dates')
                .orderBy(FieldPath.documentId, descending: true)
                .get();

            print(
                'Found ${dateSnapshot.docs.length} attendance records for $userName');

            // Process all attendance records
            List<Map<String, dynamic>> attendanceRecords = [];
            int presentDays = 0;
            int halfDays = 0;
            int absentDays = 0;

            for (var dateDoc in dateSnapshot.docs) {
              Map<String, dynamic> attendanceData =
                  dateDoc.data() as Map<String, dynamic>;
              String dateId = dateDoc.id;

              String checkInTime =
                  attendanceData['checkInTime']?.toString() ?? 'Not recorded';
              String checkOutTime =
                  attendanceData['checkOutTime']?.toString() ?? 'Not recorded';
              String status = attendanceData['status']?.toString() ?? 'absent';
              String formattedTime =
                  attendanceData['formattedTime']?.toString() ??
                      'Not calculated';
              String elapsedTime =
                  attendanceData['elapsedTime']?.toString() ?? 'Not calculated';

              // Determine attendance status
              String attendanceStatus = 'Absent';
              if (checkInTime != 'Not recorded' && checkInTime.isNotEmpty) {
                String attendanceStatusField =
                    attendanceData['attendance_status']
                            ?.toString()
                            .toLowerCase() ??
                        'absent';

                if (attendanceStatusField == 'present') {
                  attendanceStatus = 'Present';
                  presentDays++;
                } else if (attendanceStatusField == 'half day present') {
                  attendanceStatus = 'Half Day';
                  halfDays++;
                } else {
                  attendanceStatus = 'Absent';
                  absentDays++;
                }
              } else {
                absentDays++;
              }

              attendanceRecords.add({
                'date': dateId,
                'checkInTime': checkInTime,
                'checkOutTime': checkOutTime,
                'status': status,
                'formattedTime': formattedTime,
                'elapsedTime': elapsedTime,
                'attendanceStatus': attendanceStatus,
              });
            }

            employeeList.add({
              'userId': userId,
              'eid': eid,
              'name': userName,
              'email': email,
              'attendanceRecords': attendanceRecords,
              'presentDays': presentDays,
              'halfDays': halfDays,
              'absentDays': absentDays,
              'totalRecords': attendanceRecords.length,
              'profileImageUrl': userData['profileImageUrl'],
              'profilePicBinary': userData['profilePicBinary'],
            });

            print(
                'Loaded employee: $userName ($eid) - Records: ${attendanceRecords.length}, Present: $presentDays, Half Day: $halfDays, Absent: $absentDays');
          }
        } catch (e) {
          print('Error loading employee $userId: $e');
        }
      }

      // Sort employees by attendance status (Present first, then Half Day, then Absent)
      employeeList.sort((a, b) {
        int statusOrder(String status) {
          switch (status) {
            case 'Present':
              return 0;
            case 'Half Day':
              return 1;
            case 'Absent':
              return 2;
            default:
              return 3;
          }
        }

        return statusOrder(a['attendanceStatus'])
            .compareTo(statusOrder(b['attendanceStatus']));
      });

      setState(() {
        _employees = employeeList;
        _filteredEmployees = List.from(employeeList);
        _isLoading = false;
      });

      print('Successfully loaded ${employeeList.length} employees');
    } catch (e) {
      print('Error loading employees: $e');
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

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    Color statusColor;
    IconData statusIcon;

    switch (employee['attendanceStatus']) {
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
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
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'EID: ${employee['eid']}',
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      employee['attendanceStatus'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Attendance details
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Check-In',
                            employee['checkInTime'] != 'N/A' &&
                                    employee['checkInTime'].isNotEmpty
                                ? DateFormat('HH:mm').format(
                                    DateTime.parse(employee['checkInTime']))
                                : 'N/A',
                            Icons.login,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            'Check-Out',
                            employee['checkOutTime'] != 'N/A' &&
                                    employee['checkOutTime'].isNotEmpty
                                ? DateFormat('HH:mm').format(
                                    DateTime.parse(employee['checkOutTime']))
                                : 'N/A',
                            Icons.logout,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Duration',
                            employee['formattedTime'] != 'N/A'
                                ? employee['formattedTime']
                                : 'N/A',
                            Icons.timer,
                            Colors.purple,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            'Status',
                            employee['status'],
                            Icons.info,
                            Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Employee Attendance - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEmployeesWithAttendance,
            tooltip: 'Refresh',
          ),
        ],
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
                            '${_employees.length} Total',
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
                            '${_employees.where((e) => e['attendanceStatus'] == 'Present').length} Present',
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
                          Icon(Icons.schedule, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${_employees.where((e) => e['attendanceStatus'] == 'Half Day').length} Half Day',
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
                          Icon(Icons.cancel, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${_employees.where((e) => e['attendanceStatus'] == 'Absent').length} Absent',
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
                            SizedBox(height: 8),
                            Text(
                              'Try refreshing or check your search criteria',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _loadEmployeesWithAttendance,
        backgroundColor: Colors.blue[700],
        child: Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh Data',
      ),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Set up auto-refresh every 5 minutes
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      setState(() {
        // This will trigger a rebuild and refresh the StreamBuilder
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Location Tracking"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Manual refresh
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('live_locations').snapshots(),
        builder: (context, snapshot) {
          print(
              'TrackingScreen - Connection State: ${snapshot.connectionState}');
          print('TrackingScreen - Has Data: ${snapshot.hasData}');
          if (snapshot.hasData) {
            print(
                'TrackingScreen - Documents Count: ${snapshot.data!.docs.length}');
            snapshot.data!.docs.forEach((doc) {
              print('TrackingScreen - Document ID: ${doc.id}');
              print('TrackingScreen - Document Data: ${doc.data()}');
            });
          }
          if (snapshot.hasError) {
            print('TrackingScreen - Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Error loading location data",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No employee location data available",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Employees will appear here when they share their location",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Force refresh
                      });
                    },
                    child: Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final locationDocs = snapshot.data!.docs;
          print(
              'TrackingScreen - Building ListView with ${locationDocs.length} items');

          return Column(
            children: [
              // Debug info at top
              Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Debug: Found ${locationDocs.length} documents in live_locations collection',
                  style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  itemCount: locationDocs.length,
                  itemBuilder: (context, index) {
                    final locationData =
                        locationDocs[index].data() as Map<String, dynamic>;
                    final String userId = locationDocs[index].id;

                    print(
                        'TrackingScreen - Processing document $index: $userId');
                    print('TrackingScreen - Document data: $locationData');

                    // Extract location data directly from live_locations
                    final employeeName =
                        locationData['name'] ?? 'Unknown Employee';
                    final latitude =
                        locationData['latitude']?.toDouble() ?? 0.0;
                    final longitude =
                        locationData['longitude']?.toDouble() ?? 0.0;
                    final hasLocation = latitude != 0.0 && longitude != 0.0;

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              hasLocation ? Colors.green : Colors.red,
                          child: Icon(
                            hasLocation
                                ? Icons.location_on
                                : Icons.location_off,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          employeeName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          hasLocation
                              ? 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'
                              : 'Location not available',
                        ),
                        trailing: hasLocation
                            ? IconButton(
                                icon: Icon(Icons.map, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LiveLocationScreen(
                                        userId: userId,
                                        lat: latitude,
                                        lng: longitude,
                                        employeeName: employeeName,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Icon(Icons.location_disabled, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LiveLocationScreen extends StatefulWidget {
  final String userId;
  final double lat;
  final double lng;
  final String employeeName;

  const LiveLocationScreen({
    Key? key,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.employeeName,
  }) : super(key: key);

  @override
  _LiveLocationScreenState createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? userImageUrl;
  String? userImageBinary;
  Uint8List? userImageBytes;
  Timer? _locationRefreshTimer;
  double currentLat = 0.0;
  double currentLng = 0.0;
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    currentLat = widget.lat;
    currentLng = widget.lng;
    _fetchUserData();

    // Set up auto-refresh every 5 minutes for location updates
    _locationRefreshTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _refreshLocation();
    });
  }

  @override
  void dispose() {
    _locationRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLocation() async {
    try {
      DocumentSnapshot locationDoc = await FirebaseFirestore.instance
          .collection('live_locations')
          .doc(widget.userId)
          .get();

      if (locationDoc.exists) {
        final locationData = locationDoc.data() as Map<String, dynamic>;
        final newLat = locationData['latitude']?.toDouble() ?? currentLat;
        final newLng = locationData['longitude']?.toDouble() ?? currentLng;

        if (newLat != currentLat || newLng != currentLng) {
          setState(() {
            currentLat = newLat;
            currentLng = newLng;
          });

          // Animate to new location
          mapController.move(LatLng(currentLat, currentLng), 15.0);
        }
      }
    } catch (e) {
      print("Error refreshing location: $e");
    }
  }

  Future<void> _openInExternalMaps() async {
    try {
      // Open in external Google Maps application
      final url =
          'https://www.google.com/maps/search/?api=1&query=$currentLat,$currentLng';
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: show dialog with coordinates
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Open in Google Maps'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Employee: ${widget.employeeName}'),
                  SizedBox(height: 8),
                  Text('Latitude: $currentLat'),
                  Text('Longitude: $currentLng'),
                  SizedBox(height: 16),
                  Text('Copy this URL to open in browser:'),
                  SizedBox(height: 8),
                  SelectableText(url),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Copy URL'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('URL copied to clipboard')),
                    );
                  },
                ),
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error opening external maps: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening maps: $e')),
      );
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
          userImageUrl = userData!['profileImageUrl'];
          userImageBinary = userData!['profilePicBinary'];

          if (userImageBinary != null && userImageBinary!.isNotEmpty) {
            try {
              userImageBytes = base64Decode(userImageBinary!);
            } catch (e) {
              print("Error decoding user image: $e");
            }
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = LatLng(currentLat, currentLng);

    return Scaffold(
      appBar: AppBar(
        title: Text("Tracking ${widget.employeeName}"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshLocation,
            tooltip: 'Refresh Location',
          ),
          IconButton(
            icon: Icon(Icons.open_in_new),
            onPressed: () {
              // Open in external maps app
              _openInExternalMaps();
            },
            tooltip: 'Open in Maps App',
          ),
        ],
      ),
      body: Stack(
        children: [
          // The interactive map with a custom marker.
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: position,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: position,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: userImageBytes != null
                          ? ClipOval(
                              child: Image.memory(
                                userImageBytes!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (userImageUrl != null && userImageUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    userImageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        color: Colors.blueAccent,
                                        size: 40,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: Colors.blueAccent,
                                  size: 40,
                                )),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Positioned top overlay: User info card
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: userImageBytes != null
                          ? MemoryImage(userImageBytes!)
                          : (userImageUrl != null && userImageUrl!.isNotEmpty
                              ? NetworkImage(userImageUrl!)
                              : null),
                      child: (userImageUrl == null && userImageBytes == null)
                          ? Icon(Icons.person, size: 30, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.employeeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Live Location",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Last updated: ${DateTime.now().toString().substring(11, 19)}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.green[600],
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Positioned bottom overlay: Coordinates card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.black87,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Coordinates",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Latitude",
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              position.latitude.toStringAsFixed(6),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Longitude",
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              position.longitude.toStringAsFixed(6),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating action button to re-center the map
          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              onPressed: () {
                // Re-center the map to current employee location
                mapController.move(LatLng(currentLat, currentLng), 15.0);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Map re-centered to ${widget.employeeName}\'s location'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          // Refresh Location Button
          Positioned(
            bottom: 180,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () async {
                await _refreshLocation();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Location refreshed for ${widget.employeeName}'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  String? _profileImageUrl;
  String? _profilePicBinary;
  Uint8List? _profileImageBytes; // ✅ FIX: Declare the variable

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is not logged in");
      return;
    }

    print("Fetching data for UID: ${user.uid}");
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("Admins")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        userData = doc.data() as Map<String, dynamic>;
        _profileImageUrl = userData!["profileImageUrl"];
        _profilePicBinary = userData!["profilePicBinary"];

        // 🔹 Print values for debugging
        print("Profile Image URL: $_profileImageUrl");
        print(
            "Profile Binary String: ${_profilePicBinary?.substring(0, 50)}..."); // Print first 50 characters

        if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
          try {
            _profileImageBytes = base64Decode(_profilePicBinary!);
            print(
                "Decoded image bytes: ${_profileImageBytes!.length} bytes"); // ✅ Confirm image bytes exist
          } catch (e) {
            print("Error decoding base64: $e"); // 🚨 Catch decoding errors
          }
        } else {
          print(
              "No profile image found in Firestore"); // 🚨 If no binary data exists
        }

        _isLoading = false;
      });
    } else {
      print("User document does not exist in Firestore");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🔹 Step 1: Read Image as Bytes
      Uint8List originalBytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(originalBytes);

      if (image == null) {
        throw Exception("Failed to decode image");
      }

      // 🔹 Step 2: Compress Image
      Uint8List compressedBytes =
          Uint8List.fromList(img.encodeJpg(image, quality: 50));

      // 🔹 Step 3: Convert to Base64 for Firestore Storage
      String base64String = base64Encode(compressedBytes);

      // 🔹 Step 4: Upload Binary to Firestore
      await FirebaseFirestore.instance
          .collection("Admins")
          .doc(user.uid)
          .update({"profilePicBinary": base64String});

      // 🔹 Step 5: Upload Image to Firebase Storage
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("profile_pictures/${user.uid}.jpg");
      await storageRef.putData(compressedBytes);
      String imageUrl = await storageRef.getDownloadURL();

      // 🔹 Step 6: Update Firestore with Image URL
      await FirebaseFirestore.instance
          .collection("Admins")
          .doc(user.uid)
          .update({"profileImageUrl": imageUrl});

      setState(() {
        _profileImageUrl = imageUrl;
        _profilePicBinary = base64String;
        _profileImageBytes = compressedBytes; // 🔹 Update UI with new image
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile picture updated successfully!")),
      );
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : userData == null
              ? Center(
                  child: Text(
                    "No profile data found",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 75,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _profileImageBytes != null
                                  ? MemoryImage(_profileImageBytes!)
                                  : (_profileImageUrl != null &&
                                          _profileImageUrl!.isNotEmpty
                                      ? NetworkImage(_profileImageUrl!)
                                      : null),
                              child: (_profileImageUrl == null &&
                                      _profileImageBytes == null)
                                  ? Icon(Icons.person,
                                      size: 70, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: _uploadProfilePicture,
                              child: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                radius: 25,
                                child: Icon(Icons.camera_alt,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        "${userData?["FirstName"] ?? "Unknown"} ${userData?["LastName"] ?? "Unknown"}",
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          userData?["Email"] ?? "No email provided",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      _buildInfoSection("Personal Info", [
                        _buildInfoRow("📅 Date of Birth",
                            userData?["DateOfBirth"] ?? "N/A"),
                        _buildInfoRow(
                            "🔢 Age", userData?["Age"]?.toString() ?? "N/A"),
                        _buildInfoRow(
                            "📞 Phone", userData?["PhoneNumber"] ?? "N/A"),
                        _buildInfoRow("⚧ Gender", userData?["Gender"] ?? "N/A"),
                      ]),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => _handleLogout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Log Out",
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () async {
                  try {
                    // Navigate to edit page and wait for result
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditProfilePage(userData: userData!),
                      ),
                    );

                    if (result == true) {
                      // Show loading indicator
                      setState(() => _isLoading = true);

                      // Refresh the profile data
                      await _fetchUserData();

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error updating profile: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating profile: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
              )
            ],
          ),
          Divider(color: Colors.grey[400], thickness: 1.2),
          SizedBox(height: 10),
          ...children
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value ?? "Not provided",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late Map<String, dynamic> userData;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        print("Attempting to update user with UID: ${userData['uid']}");

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userData['uid'])
            .get();

        if (userDoc.exists) {
          print("User document found. Proceeding with update.");

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userData['uid'])
              .update({
            'FirstName': userData['FirstName'],
            'LastName': userData['LastName'],
            'Email': userData['Email'],
            'PhoneNumber': userData['PhoneNumber'],
            'DateOfBirth': userData['DateOfBirth'],
            'Age': userData['Age'],
            'Gender': userData['Gender'],
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );

          Navigator.pop(context, true); // Return to previous page
        } else {
          print("User document not found for UID: ${userData['uid']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User document not found.')),
          );
        }
      } catch (e) {
        print("Error during update: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: userData["FirstName"],
                decoration: InputDecoration(labelText: "First Name"),
                onChanged: (value) => userData["FirstName"] = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter a first name" : null,
              ),
              TextFormField(
                initialValue: userData["LastName"],
                decoration: InputDecoration(labelText: "Last Name"),
                onChanged: (value) => userData["LastName"] = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter a last name" : null,
              ),
              TextFormField(
                initialValue: userData["Email"],
                decoration: InputDecoration(labelText: "Email"),
                onChanged: (value) => userData["Email"] = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter an email" : null,
              ),
              TextFormField(
                initialValue: userData["PhoneNumber"],
                decoration: InputDecoration(labelText: "Phone Number"),
                onChanged: (value) => userData["PhoneNumber"] = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter a phone number" : null,
              ),
              TextFormField(
                initialValue: userData["DateOfBirth"],
                decoration: InputDecoration(labelText: "Date of Birth"),
                onChanged: (value) => userData["DateOfBirth"] = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter a date of birth" : null,
              ),
              TextFormField(
                initialValue: userData["Age"]?.toString(),
                decoration: InputDecoration(labelText: "Age"),
                onChanged: (value) => userData["Age"] = int.tryParse(value),
                validator: (value) =>
                    value!.isEmpty ? "Please enter an age" : null,
              ),
              TextFormField(
                initialValue: userData["Gender"],
                decoration: InputDecoration(labelText: "Gender"),
                onChanged: (value) => userData["Gender"] = value,
                validator: (value) =>
                    value!.isEmpty ? "Please enter a gender" : null,
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

// class AccountsScreen extends StatefulWidget {
//   @override
//   _AccountsScreenState createState() => _AccountsScreenState();
// }

// class _AccountsScreenState extends State<AccountsScreen> {
//   String selectedYear = DateTime.now().year.toString();
//   String selectedMonth = _monthNames[DateTime.now().month - 1];

//   static const List<String> _monthNames = [
//     'January',
//     'February',
//     'March',
//     'April',
//     'May',
//     'June',
//     'July',
//     'August',
//     'September',
//     'October',
//     'November',
//     'December'
//   ];
//   final TextEditingController _salaryController = TextEditingController();
//   String _month = 'Month';
//   String _year = 'Year';
//   String _status = 'NA';

//   List<Map<String, dynamic>> _employees = [];
//   String? _selectedEmpId;
//   String? _selectedEmpName;

//   @override
//   void initState() {
//     super.initState();
//     _fetchEmployees();
//   }

//   Future<void> _fetchEmployees() async {
//     final snapshot = await FirebaseFirestore.instance.collection('users').get();
//     final employees = snapshot.docs.map((doc) {
//       final data = doc.data();
//       return {
//         'uid': data['uid'] ?? '',
//         'name': data['name'] ?? '',
//       };
//     }).toList();

//     setState(() {
//       _employees = employees;
//     });
//   }

//   Future<void> generatePdf(List<QueryDocumentSnapshot> docs) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) {
//           return pw.Column(
//             children: [
//               pw.Text('Salary Evaluation Report',
//                   style: pw.TextStyle(fontSize: 24)),
//               pw.SizedBox(height: 16),
//               pw.Table.fromTextArray(
//                 headers: ['Name', 'Salary', 'Month', 'Year', 'Status'],
//                 data: docs.map((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   return [
//                     data['employeeName'] ?? '',
//                     data['salary'].toString(),
//                     data['month'] ?? '',
//                     data['year'] ?? '',
//                     data['status'] ?? ''
//                   ];
//                 }).toList(),
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   Future<void> submitSalaryData({
//     required double totalSalary,
//     required double workedHours,
//     required double salaryPerHour,
//     required String branchName,
//   }) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         print("❌ User not logged in.");
//         return;
//       }

//       final uid = user.uid;

//       // Get current year and month
//       final now = DateTime.now();
//       final String year = now.year.toString();
//       final String month =
//           now.month.toString().padLeft(2, '0'); // e.g., '04' for April

//       // Prepare salary data
//       final Map<String, dynamic> salaryData = {
//         'uid': uid,
//         'year': year,
//         'month': month,
//         'branchName': branchName,
//         'totalSalary': totalSalary,
//         'workedHours': workedHours,
//         'salaryPerHour': salaryPerHour,
//         'timestamp': FieldValue.serverTimestamp(),
//       };

//       // Firestore path: salary_records/{year}/{month}/{uid}
//       await FirebaseFirestore.instance
//           .collection('salary_records')
//           .doc(year) // year-level document
//           .collection(month) // month-level subcollection
//           .doc(uid) // document named after the user ID
//           .set(salaryData);

//       print("✅ Salary data submitted successfully!");
//     } catch (e) {
//       print("❌ Error submitting salary data: $e");
//     }
//   }

//   Future<void> _saveSalaryRecord() async {
//     String salary = _salaryController.text;

//     if (_selectedEmpId == null ||
//         salary.isEmpty ||
//         _month == 'Month' ||
//         _year == 'Year' ||
//         _status == 'NA') {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please fill all fields')),
//       );
//       return;
//     }

//     await FirebaseFirestore.instance
//         .collection('salary_records')
//         .doc(_year)
//         .collection(_month)
//         .add({
//       'empId': _selectedEmpId,
//       'empName': _selectedEmpName,
//       'month': _month,
//       'year': _year,
//       'salary': salary,
//       'status': _status,
//       'timestamp': FieldValue.serverTimestamp(),
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Salary record saved successfully!')),
//     );

//     _salaryController.clear();
//     setState(() {
//       _selectedEmpId = null;
//       _selectedEmpName = null;
//       _month = 'Month';
//       _year = 'Year';
//       _status = 'NA';
//     });
//   }

//   void _generateMonthlyReport(List<QueryDocumentSnapshot> records) async {
//     final pdf = pw.Document();

//     // Extract and compute totals
//     double totalSalary = 0;
//     double totalPaid = 0;
//     double totalNotPaid = 0;

//     final tableData = records.map((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       final empName = data['empName'] ?? 'Unknown';
//       final salary = double.tryParse(data['salary']?.toString() ?? '0') ?? 0.0;
//       final status = data['status']?.toString().toLowerCase() ?? 'unknown';

//       totalSalary += salary;
//       if (status == 'paid') {
//         totalPaid += salary;
//       } else if (status == 'not paid') {
//         totalNotPaid += salary;
//       }

//       return [empName, salary.toStringAsFixed(2), status.toUpperCase()];
//     }).toList();

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(24),
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 'Monthly Salary Report',
//                 style:
//                     pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
//               ),
//               pw.SizedBox(height: 8),
//               pw.Text(
//                 '$selectedMonth $selectedYear',
//                 style: pw.TextStyle(fontSize: 18),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Table.fromTextArray(
//                 headers: ['Employee Name', 'Salary (Rs)', 'Status'],
//                 data: tableData,
//                 headerStyle: pw.TextStyle(
//                   fontWeight: pw.FontWeight.bold,
//                   color: PdfColors.white,
//                 ),
//                 headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey),
//                 border: pw.TableBorder.all(color: PdfColors.grey),
//                 cellAlignment: pw.Alignment.centerLeft,
//                 cellPadding:
//                     const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text(
//                 'Total Salary: Rs.${totalSalary.toStringAsFixed(2)}',
//                 style:
//                     pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
//               ),
//               pw.SizedBox(height: 10),
//               pw.Text(
//                 'Total Paid: Rs.${totalPaid.toStringAsFixed(2)}',
//                 style: pw.TextStyle(fontSize: 12),
//               ),
//               pw.Text(
//                 'Total Not Paid: Rs.${totalNotPaid.toStringAsFixed(2)}',
//                 style: pw.TextStyle(fontSize: 12),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text(
//                 'Generated on: ${DateTime.now().toLocal()}',
//                 style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     Uint8List pdfBytes = await pdf.save();

//     await Printing.sharePdf(
//       bytes: pdfBytes,
//       filename: 'Salary_Report_${selectedMonth}_$selectedYear.pdf',
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               // Employee Dropdown
//               _buildEmployeeDropdown(),

//               SizedBox(height: 16),

//               // Salary Input
//               _buildSalaryInput(),

//               SizedBox(height: 16),

//               // Month, Year, Status Dropdowns
//               _buildMonthYearStatusRow(),

//               SizedBox(height: 24),

//               // Save Button
//               ElevatedButton(
//                 onPressed: _saveSalaryRecord,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.indigo[900],
//                   padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                 ),
//                 child:
//                     Text("Save Record", style: TextStyle(color: Colors.white)),
//               ),

//               SizedBox(height: 24),

//               // Salary Records
//               Text("Salary Records",
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//               SizedBox(height: 8),
//               // Year Dropdown
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Row(
//                   children: [
//                     Text("Select Year: "),
//                     DropdownButton<String>(
//                       value: selectedYear,
//                       items: ['2023', '2024', '2025'].map((year) {
//                         return DropdownMenuItem(
//                           value: year,
//                           child: Text(year),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           selectedYear = value!;
//                         });
//                       },
//                     ),
//                     SizedBox(width: 20),
//                     Text("Month: "),
//                     DropdownButton<String>(
//                       value: selectedMonth,
//                       items: _monthNames.map((month) {
//                         return DropdownMenuItem(
//                           value: month,
//                           child: Text(month),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           selectedMonth = value!;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               _buildSalaryRecordsTable(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmployeeDropdown() {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.indigo[900],
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: _selectedEmpId,
//           hint: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child:
//                 Text("Select Employee", style: TextStyle(color: Colors.white)),
//           ),
//           icon: Icon(Icons.arrow_drop_down, color: Colors.white),
//           dropdownColor: Colors.indigo[900],
//           style: TextStyle(color: Colors.white),
//           onChanged: (String? newValue) {
//             final selected = _employees.firstWhere((e) => e['uid'] == newValue);
//             setState(() {
//               _selectedEmpId = newValue;
//               _selectedEmpName = selected['name'];
//             });
//           },
//           items: _employees.map((employee) {
//             return DropdownMenuItem<String>(
//               value: employee['uid'],
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Text(employee['name']),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildSalaryInput() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[200],
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: TextField(
//         controller: _salaryController,
//         keyboardType: TextInputType.number,
//         decoration: InputDecoration(
//           hintText: "Enter Salary",
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.all(16),
//         ),
//       ),
//     );
//   }

//   Widget _buildMonthYearStatusRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             children: [
//               _buildDropdown(
//                 value: _month,
//                 options: [
//                   'Month',
//                   'January',
//                   'February',
//                   'March',
//                   'April',
//                   'May',
//                   'June',
//                   'July',
//                   'August',
//                   'September',
//                   'October',
//                   'November',
//                   'December'
//                 ],
//                 onChanged: (val) => setState(() => _month = val!),
//               ),
//               SizedBox(height: 8),
//               _buildDropdown(
//                 value: _year,
//                 options: ['Year', '2023', '2024', '2025', '2026'],
//                 onChanged: (val) => setState(() => _year = val!),
//               ),
//             ],
//           ),
//         ),
//         SizedBox(width: 16),
//         Expanded(
//           child: _buildDropdown(
//             value: _status,
//             options: ['NA', 'Paid', 'Not Paid'],
//             onChanged: (val) => setState(() => _status = val!),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdown({
//     required String value,
//     required List<String> options,
//     required ValueChanged<String?> onChanged,
//   }) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.indigo[900],
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: value,
//           icon: Icon(Icons.arrow_drop_down, color: Colors.white),
//           dropdownColor: Colors.indigo[900],
//           style: TextStyle(color: Colors.white),
//           onChanged: onChanged,
//           items: options.map<DropdownMenuItem<String>>((String val) {
//             return DropdownMenuItem<String>(
//               value: val,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Text(val),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildSalaryRecordsTable() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('salary_records')
//           .doc(selectedYear)
//           .collection(selectedMonth)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//               child: Text('No data found for $selectedMonth $selectedYear'));
//         }

//         final records = snapshot.data!.docs;

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Report Generation Button
//             Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   _generateMonthlyReport(
//                       records); // Call your report logic here
//                 },
//                 icon: Icon(Icons.picture_as_pdf),
//                 label: Text("Generate Report"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                 ),
//               ),
//             ),
//             SizedBox(height: 10),
//             // Salary Table
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   _buildTableHeader(),
//                   ...records.map((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     return _buildSalaryRow(
//                       data['empName'] ?? '',
//                       '${data['month']} ${data['year']}',
//                       '₹${data['salary']}',
//                       data['status'] ?? '',
//                     );
//                   }).toList(),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Table Header
//   Widget _buildTableHeader() {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//       decoration: BoxDecoration(
//         color: Colors.indigo[800],
//         borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//               flex: 3,
//               child:
//                   Text('Employee Name', style: TextStyle(color: Colors.white))),
//           Expanded(
//               flex: 2,
//               child: Text('Month-Year', style: TextStyle(color: Colors.white))),
//           Expanded(
//               flex: 2,
//               child: Text('Salary', style: TextStyle(color: Colors.white))),
//           Expanded(
//               flex: 2,
//               child: Text('Status', style: TextStyle(color: Colors.white))),
//         ],
//       ),
//     );
//   }

// // Row for each salary record
//   Widget _buildSalaryRow(
//       String name, String monthYear, String salary, String status) {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//       decoration: BoxDecoration(
//         border: Border(top: BorderSide(color: Colors.grey.shade300)),
//         color: Colors.white,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(flex: 3, child: Text(name)),
//           Expanded(flex: 2, child: Text(monthYear)),
//           Expanded(flex: 2, child: Text(salary)),
//           Expanded(flex: 2, child: Text(status)),
//         ],
//       ),
//     );
//   }
// }

// Active Users Page - Shows employees currently checked in
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
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      DateTime now = DateTime.now();

      print('Loading active users for date: $currentDate');
      print('Current time: ${now.hour}:${now.minute}');

      // Get all users first
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> activeUsers = [];

      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Check today's attendance for this user
        try {
          DocumentSnapshot todayAttendance = await FirebaseFirestore.instance
              .collection('attendance')
              .doc(userId)
              .collection('dates')
              .doc(currentDate)
              .get();

          if (todayAttendance.exists) {
            Map<String, dynamic> attendanceData =
                todayAttendance.data() as Map<String, dynamic>;

            String checkInTime =
                attendanceData['checkInTime']?.toString() ?? '';
            String checkOutTime =
                attendanceData['checkOutTime']?.toString() ?? '';

            // Parse check-in time
            if (checkInTime.isNotEmpty && checkInTime != 'Not recorded') {
              DateTime? checkInDateTime =
                  _parseTimeToDateTime(checkInTime, currentDate);

              if (checkInDateTime != null) {
                bool isActive = false;

                // If no checkout time or checkout time is empty/null, user is still active
                if (checkOutTime.isEmpty ||
                    checkOutTime == 'Not recorded' ||
                    checkOutTime == 'null') {
                  // User checked in but hasn't checked out - they're active
                  if (now.isAfter(checkInDateTime)) {
                    isActive = true;
                  }
                } else {
                  // User has both check-in and check-out times
                  DateTime? checkOutDateTime =
                      _parseTimeToDateTime(checkOutTime, currentDate);

                  if (checkOutDateTime != null) {
                    // User is active if current time is between check-in and check-out
                    if (now.isAfter(checkInDateTime) &&
                        now.isBefore(checkOutDateTime)) {
                      isActive = true;
                    }
                  }
                }

                if (isActive) {
                  activeUsers.add({
                    'userId': userId,
                    'name': userData['name'] ?? 'Unknown',
                    'email': userData['email'] ?? 'No email',
                    'profileImageUrl': userData['profileImageUrl'],
                    'profilePicBinary': userData['profilePicBinary'],
                    'checkInTime': checkInTime,
                    'checkOutTime':
                        checkOutTime.isEmpty || checkOutTime == 'Not recorded'
                            ? 'Still Active'
                            : checkOutTime,
                    'isCurrentlyActive': true,
                  });
                }
              }
            }
          }
        } catch (e) {
          print('Error checking attendance for user $userId: $e');
        }
      }

      setState(() {
        _activeUsers = activeUsers;
        _isLoading = false;
      });

      print('Found ${activeUsers.length} active users');
    } catch (e) {
      print('Error loading active users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _parseTimeToDateTime(String timeString, String dateString) {
    try {
      // Handle different time formats
      if (timeString.contains(':')) {
        List<String> timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);

          DateTime baseDate = DateTime.parse(dateString);
          return DateTime(
              baseDate.year, baseDate.month, baseDate.day, hour, minute);
        }
      }
    } catch (e) {
      print('Error parsing time $timeString: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Users'),
        backgroundColor: Colors.green[100],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadActiveUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _activeUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No active users found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No employees are currently checked in',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                      return _buildActiveUserCard(_activeUsers[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildActiveUserCard(Map<String, dynamic> user) {
    Uint8List? imageBytes;

    if (user['profilePicBinary'] != null &&
        user['profilePicBinary'].isNotEmpty) {
      try {
        imageBytes = base64Decode(user['profilePicBinary']);
      } catch (e) {
        print('Error decoding image: $e');
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(
                userId: user['userId'],
                userData: user,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green[100],
                      backgroundImage: imageBytes != null
                          ? MemoryImage(imageBytes)
                          : (user['profileImageUrl'] != null
                              ? NetworkImage(user['profileImageUrl'])
                              : null),
                      child:
                          imageBytes == null && user['profileImageUrl'] == null
                              ? Icon(Icons.person,
                                  size: 30, color: Colors.green[700])
                              : null,
                    ),
                    SizedBox(width: 16),

                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            user['email'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Status Badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Attendance Times
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.login,
                                    size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Check In',
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
                              user['checkInTime'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.logout,
                                    size: 16, color: Colors.orange),
                                SizedBox(width: 4),
                                Text(
                                  'Check Out',
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
                              user['checkOutTime'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: user['checkOutTime'] == 'Still Active'
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ],
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
    );
  }
}

// Inactive Users Page - Shows employees not currently checked in
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
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      DateTime now = DateTime.now();

      print('Loading inactive users for date: $currentDate');

      // Get all users first
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> inactiveUsers = [];

      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Check today's attendance for this user
        try {
          DocumentSnapshot todayAttendance = await FirebaseFirestore.instance
              .collection('attendance')
              .doc(userId)
              .collection('dates')
              .doc(currentDate)
              .get();

          bool isInactive = true;
          String attendanceStatus = 'Not checked in today';
          String checkInTime = 'N/A';
          String checkOutTime = 'N/A';

          if (todayAttendance.exists) {
            Map<String, dynamic> attendanceData =
                todayAttendance.data() as Map<String, dynamic>;

            String checkInTimeStr =
                attendanceData['checkInTime']?.toString() ?? '';
            String checkOutTimeStr =
                attendanceData['checkOutTime']?.toString() ?? '';

            checkInTime = checkInTimeStr.isNotEmpty ? checkInTimeStr : 'N/A';
            checkOutTime =
                checkOutTimeStr.isNotEmpty && checkOutTimeStr != 'Not recorded'
                    ? checkOutTimeStr
                    : 'N/A';

            // Parse check-in time
            if (checkInTimeStr.isNotEmpty && checkInTimeStr != 'Not recorded') {
              DateTime? checkInDateTime =
                  _parseTimeToDateTime(checkInTimeStr, currentDate);

              if (checkInDateTime != null) {
                // If no checkout time or checkout time is empty/null, user is still active
                if (checkOutTimeStr.isEmpty ||
                    checkOutTimeStr == 'Not recorded' ||
                    checkOutTimeStr == 'null') {
                  // User checked in but hasn't checked out - they're active, so not inactive
                  if (now.isAfter(checkInDateTime)) {
                    isInactive = false;
                  }
                } else {
                  // User has both check-in and check-out times
                  DateTime? checkOutDateTime =
                      _parseTimeToDateTime(checkOutTimeStr, currentDate);

                  if (checkOutDateTime != null) {
                    if (now.isAfter(checkOutDateTime)) {
                      // User has checked out - they're inactive
                      attendanceStatus = 'Checked out';
                      isInactive = true;
                    } else if (now.isAfter(checkInDateTime) &&
                        now.isBefore(checkOutDateTime)) {
                      // User is currently active
                      isInactive = false;
                    }
                  }
                }
              }
            }
          }

          if (isInactive) {
            inactiveUsers.add({
              'userId': userId,
              'name': userData['name'] ?? 'Unknown',
              'email': userData['email'] ?? 'No email',
              'profileImageUrl': userData['profileImageUrl'],
              'profilePicBinary': userData['profilePicBinary'],
              'checkInTime': checkInTime,
              'checkOutTime': checkOutTime,
              'attendanceStatus': attendanceStatus,
              'isCurrentlyActive': false,
            });
          }
        } catch (e) {
          print('Error checking attendance for user $userId: $e');
          // If there's an error, consider them inactive
          inactiveUsers.add({
            'userId': userId,
            'name': userData['name'] ?? 'Unknown',
            'email': userData['email'] ?? 'No email',
            'profileImageUrl': userData['profileImageUrl'],
            'profilePicBinary': userData['profilePicBinary'],
            'checkInTime': 'N/A',
            'checkOutTime': 'N/A',
            'attendanceStatus': 'No attendance data',
            'isCurrentlyActive': false,
          });
        }
      }

      setState(() {
        _inactiveUsers = inactiveUsers;
        _isLoading = false;
      });

      print('Found ${inactiveUsers.length} inactive users');
    } catch (e) {
      print('Error loading inactive users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _parseTimeToDateTime(String timeString, String dateString) {
    try {
      // Handle different time formats
      if (timeString.contains(':')) {
        List<String> timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);

          DateTime baseDate = DateTime.parse(dateString);
          return DateTime(
              baseDate.year, baseDate.month, baseDate.day, hour, minute);
        }
      }
    } catch (e) {
      print('Error parsing time $timeString: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inactive Users'),
        backgroundColor: Colors.red[100],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInactiveUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _inactiveUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No inactive users found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All employees are currently active!',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                      return _buildInactiveUserCard(_inactiveUsers[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildInactiveUserCard(Map<String, dynamic> user) {
    Uint8List? imageBytes;

    if (user['profilePicBinary'] != null &&
        user['profilePicBinary'].isNotEmpty) {
      try {
        imageBytes = base64Decode(user['profilePicBinary']);
      } catch (e) {
        print('Error decoding image: $e');
      }
    }

    Color statusColor =
        user['attendanceStatus'] == 'Checked out' ? Colors.orange : Colors.red;
    IconData statusIcon = user['attendanceStatus'] == 'Checked out'
        ? Icons.logout
        : Icons.person_off;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(
                userId: user['userId'],
                userData: user,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: statusColor.withOpacity(0.1),
                      backgroundImage: imageBytes != null
                          ? MemoryImage(imageBytes)
                          : (user['profileImageUrl'] != null
                              ? NetworkImage(user['profileImageUrl'])
                              : null),
                      child:
                          imageBytes == null && user['profileImageUrl'] == null
                              ? Icon(Icons.person, size: 30, color: statusColor)
                              : null,
                    ),
                    SizedBox(width: 16),

                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            user['email'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Inactive Status Badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          SizedBox(width: 4),
                          Text(
                            'INACTIVE',
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

                SizedBox(height: 16),

                // Status and Attendance Times
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Status
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: statusColor),
                          SizedBox(width: 8),
                          Text(
                            'Status: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            user['attendanceStatus'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Times (if available)
                      if (user['checkInTime'] != 'N/A' ||
                          user['checkOutTime'] != 'N/A')
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.login,
                                          size: 16, color: Colors.green),
                                      SizedBox(width: 4),
                                      Text(
                                        'Check In',
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
                                    user['checkInTime'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: user['checkInTime'] != 'N/A'
                                          ? Colors.green[700]
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.logout,
                                          size: 16, color: Colors.orange),
                                      SizedBox(width: 4),
                                      Text(
                                        'Check Out',
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
                                    user['checkOutTime'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: user['checkOutTime'] != 'N/A'
                                          ? Colors.orange[700]
                                          : Colors.grey,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// User Detail Screen - Shows complete user information
class UserDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? userData;

  const UserDetailScreen({
    Key? key,
    required this.userId,
    this.userData,
  }) : super(key: key);

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  Map<String, dynamic>? _todayAttendance;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _userData = widget.userData;
      _isLoading = false;
    }
    _loadUserData();
    _loadTodayAttendance();
  }

  Future<void> _loadUserData() async {
    if (widget.userData != null) return; // Data already provided

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTodayAttendance() async {
    try {
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      DocumentSnapshot todayAttendance = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(widget.userId)
          .collection('dates')
          .doc(currentDate)
          .get();

      if (todayAttendance.exists) {
        setState(() {
          _todayAttendance = todayAttendance.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error loading today\'s attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('User Details'),
          backgroundColor: Colors.blue[100],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('User Details'),
          backgroundColor: Colors.blue[100],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'User data not found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    Uint8List? imageBytes;
    if (_userData!['profilePicBinary'] != null &&
        _userData!['profilePicBinary'].isNotEmpty) {
      try {
        imageBytes = base64Decode(_userData!['profilePicBinary']);
      } catch (e) {
        print('Error decoding image: $e');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_userData!['name'] ?? 'User'} Details'),
        backgroundColor: Colors.blue[100],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: imageBytes != null
                          ? MemoryImage(imageBytes)
                          : (_userData!['profileImageUrl'] != null
                              ? NetworkImage(_userData!['profileImageUrl'])
                              : null),
                      child: imageBytes == null &&
                              _userData!['profileImageUrl'] == null
                          ? Icon(Icons.person,
                              size: 60, color: Colors.blue[400])
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _userData!['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _userData!['email'] ?? 'No email',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Today's Attendance Card
            if (_todayAttendance != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.today, color: Colors.green, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Today\'s Attendance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAttendanceDetail(
                              'Check In',
                              _todayAttendance!['checkInTime']?.toString() ??
                                  'Not recorded',
                              Icons.login,
                              Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildAttendanceDetail(
                              'Check Out',
                              _todayAttendance!['checkOutTime']?.toString() ??
                                  'Not recorded',
                              Icons.logout,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (_todayAttendance!['elapsedTime'] != null) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule,
                                  color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Total Duration: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                _todayAttendance!['elapsedTime'].toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Personal Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow('Full Name', _userData!['name']),
                    _buildInfoRow('Email', _userData!['email']),
                    _buildInfoRow('Phone', _userData!['phone']),
                    _buildInfoRow('Age', _userData!['age']?.toString()),
                    _buildInfoRow('Gender', _userData!['Gender']),
                    _buildInfoRow('Address', _userData!['address']),
                    _buildInfoRow(
                        'Emergency Contact', _userData!['emergencyContact']),
                    _buildInfoRow('Blood Group', _userData!['bloodGroup']),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Professional Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work_outline,
                            color: Colors.orange, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Professional Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(
                        'Employee ID', _userData!['uid'] ?? widget.userId),
                    _buildInfoRow('Department', _userData!['department']),
                    _buildInfoRow('Position', _userData!['position']),
                    _buildInfoRow('Join Date', _userData!['joinDate']),
                    _buildInfoRow('Salary', _userData!['salary']?.toString()),
                    _buildInfoRow('Manager', _userData!['manager']),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeAttendanceDetailScreen(
                            employeeId: widget.userId,
                            employeeName: _userData!['name'] ?? 'Unknown',
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.calendar_today),
                    label: Text('View Attendance History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceDetail(
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

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value != null ? Colors.black87 : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
