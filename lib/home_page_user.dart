import 'dart:convert';
import 'dart:io';
import 'package:consultancy/loginpage.dart';
import 'package:consultancy/models/schedule_model.dart';
import 'package:consultancy/services/schedule_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:local_auth/local_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Timer? _locationTimer;
  DateTime? _lastLocationUpdate;

  final List<Widget> _pages = [
    HomeScreen(),
    SchedulePage(),
    AttendanceScreen(),
    AccountsScreen(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _startSimpleLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startSimpleLocationTracking() async {
    print('Starting location tracking...');

    // Start location tracking every 5 minutes when app is active
    _locationTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      print('Timer triggered - updating location...');
      await _updateLocationToFirestore();
    });

    // Also send location immediately
    print('Sending initial location...');
    await _updateLocationToFirestore();
  }

  Future<void> _updateLocationToFirestore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in, skipping location update');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          print('Location permission denied.');
          return;
        }
      }

      print('Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String? name = (userDoc.data() as Map<String, dynamic>?)?['name'] ??
          user.email ??
          'Unknown';

      await FirebaseFirestore.instance
          .collection('live_locations')
          .doc(user.uid)
          .set({
        'name': name,
        'id': user.uid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdate': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      setState(() {
        _lastLocationUpdate = DateTime.now();
      });

      print('Location updated successfully at ${DateTime.now()}');
      print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    } catch (e) {
      print('Error sending location: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        toolbarHeight: 70, // Increase the height of the AppBar
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTitle(_selectedIndex),
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_lastLocationUpdate != null)
              Text(
                'Location: ${DateFormat('HH:mm').format(_lastLocationUpdate!)}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        leading: _selectedIndex == 0
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
        actions: [
          if (_lastLocationUpdate != null)
            IconButton(
              icon: Icon(
                Icons.location_on,
                color: Colors.green,
                size: 20,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Location last updated: ${DateFormat('HH:mm:ss').format(_lastLocationUpdate!)}'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          _bottomNavItem(Icons.home, "HOME"),
          _bottomNavItem(Icons.schedule, "Schedule"),
          _bottomNavItem(Icons.assignment, "Attendance"),
          _bottomNavItem(Icons.account_balance, "Accounts"),
          _bottomNavItem(Icons.person, "Profile"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }

  BottomNavigationBarItem _bottomNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 1:
        return "SCHEDULES";
      case 2:
        return "ATTENDANCE";
      case 3:
        return "ACCOUNTS";
      case 4:
        return "PROFILE";
      default:
        return "Welcome To SSM";
    }
  }
}

// Screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: DashboardPage(),
    );
  }
}

// Dashboard Widget with Firebase Name Fetching
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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
        .collection("users")
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
          _buildQuickAccessSection(),
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
                  userData != null ? userData!["name"] ?? "Unknown" : "Unknown",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Employee",
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Access",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _quickAccessItems.length,
            itemBuilder: (context, index) {
              return _buildQuickAccessItem(
                _quickAccessItems[index]['icon'],
                _quickAccessItems[index]['label'],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        if (label == "My Attendance") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AttendanceScreen()),
          );
        } else if (label == "My Schedule") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SchedulePage()),
          );
        } else if (label == "My Accounts") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccountsScreen()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _quickAccessItems = [
    {'icon': Icons.calendar_today, 'label': "My Schedule"},
    {'icon': Icons.assignment, 'label': "My Attendance"},
    {'icon': Icons.account_balance, 'label': "My Accounts"},
  ];
}

//Schedule Screen

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDate = DateTime.now();
  late DateTime _selectedDate;

  List<ScheduleModel> _allSchedules = [];
  Map<String, UserModel> _usersMap = {};
  final ScheduleService _scheduleService = ScheduleService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _showAllSchedules =
      false; // Toggle to show all schedules or date-specific

  @override
  void initState() {
    super.initState();
    _selectedDate = _focusedDate;
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not authenticated';
        });
        return;
      }

      final data = await _scheduleService.refreshScheduleData();

      setState(() {
        _allSchedules = data['schedules'] as List<ScheduleModel>;
        _usersMap = data['usersMap'] as Map<String, UserModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load schedules: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ScheduleModel> getSchedulesForSelectedDate() {
    return _scheduleService.getSchedulesForDate(_allSchedules, _selectedDate);
  }

  List<ScheduleModel> getAllUserSchedules() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    // Return all schedules assigned to the current user, sorted by start date
    return _allSchedules.where((schedule) {
      return schedule.assignedEmployees.contains(currentUser.uid);
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  bool _isScheduledDay(DateTime date) {
    return _scheduleService.hasScheduleForDate(_allSchedules, date);
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    });
  }

  String _formatScheduleDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Work Schedule'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showAllSchedules ? Icons.calendar_today : Icons.list),
            onPressed: () {
              setState(() {
                _showAllSchedules = !_showAllSchedules;
              });
            },
            tooltip: _showAllSchedules
                ? 'Show date schedules'
                : 'Show all schedules',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadScheduleData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMonthNavigation(),
                _buildWeekDays(),
                _buildCalendar(),
                Divider(height: 1),
                _buildScheduleHeader(),
                Expanded(child: _buildScheduleList()),
              ],
            ),
    );
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: _goToPreviousMonth,
          ),
          Text(
            DateFormat.yMMMM().format(_focusedDate),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: days
          .map((day) => Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      day,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];

    // Add empty containers for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    // Add day cells for each day in the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final isSelected = _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;
      final hasSchedule = _isScheduledDay(date);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue
                      : hasSchedule
                          ? Colors.green.withOpacity(0.3)
                          : null,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight:
                        hasSchedule ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (hasSchedule)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: dayWidgets,
      ),
    );
  }

  Widget _buildScheduleHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _showAllSchedules
                  ? 'All My Schedules (${getAllUserSchedules().length})'
                  : 'Schedules for ${DateFormat.yMMMMd().format(_selectedDate)} (${getSchedulesForSelectedDate().length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_showAllSchedules)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Text(
                'Selected Date',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    // Choose which schedules to show based on toggle
    final schedules = _showAllSchedules
        ? getAllUserSchedules()
        : getSchedulesForSelectedDate();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error loading schedules',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadScheduleData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _showAllSchedules
                  ? 'No work schedules found for your account'
                  : 'No work scheduled for ${DateFormat.yMMMMd().format(_selectedDate)}',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_showAllSchedules)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Contact your administrator if you believe this is an error',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: schedules.length,
      physics: BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final assignedEmployeeNames =
            _scheduleService.getAssignedEmployeeNames(schedule, _usersMap);
        final isAssignedToCurrentUser =
            schedule.assignedEmployees.contains(currentUser?.uid);

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              schedule.branchName.isEmpty
                                  ? 'Unknown Branch'
                                  : schedule.branchName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAssignedToCurrentUser)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.notifications_active,
                                  color: Colors.red, size: 20),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(schedule.getDisplayStatus()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        schedule.getDisplayStatus(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _buildScheduleDetailRow(Icons.calendar_today,
                    'Period: ${_formatScheduleDate(schedule.startDate)} - ${_formatScheduleDate(schedule.endDate)}'),
                _buildScheduleDetailRow(Icons.access_time,
                    'Time: ${schedule.startTime.isEmpty ? '-' : schedule.startTime} to ${schedule.endTime.isEmpty ? '-' : schedule.endTime}'),
                _buildScheduleDetailRow(
                    Icons.hourglass_top, 'Total Hours: ${schedule.totalHours}'),
                _buildScheduleDetailRow(Icons.people,
                    'Workers Needed: ${schedule.numberOfWorkers}'),
                _buildScheduleDetailRow(Icons.people,
                    'Workers Assigned: ${schedule.assignedEmployees.length}'),
                _buildScheduleDetailRow(Icons.person,
                    'Assigned Employees: ${assignedEmployeeNames.join(', ')}'),
                if (schedule.isExpired())
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                              color: Colors.red.shade700, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This work has expired. The end date has passed and status is "not done".',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
      },
    );
  }

  Widget _buildScheduleDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.deepOrange;
      case 'not done':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

//Attendance Screen
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool isTiming = false;
  DateTime? startTime;
  Timer? _timer;
  Duration elapsedTime = Duration(seconds: 0);
  DateTime? checkInTime;
  DateTime? checkOutTime;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTimerState(); // Load the previous timer state if exists
  }

  /// Load previous timer state
  Future<void> _loadTimerState() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool wasTiming = prefs.getBool('isTiming') ?? false;
      String? savedStartTime = prefs.getString('startTime');
      String? savedCheckInTime = prefs.getString('checkInTime');

      // First check if user is logged in
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User is not logged in during _loadTimerState");
        setState(() {
          isLoading = false;
        });

        // Wait a moment and try again - sometimes Firebase Auth takes a moment to initialize
        await Future.delayed(Duration(seconds: 2));
        if (FirebaseAuth.instance.currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Not logged in. Please sign in again."),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  _loadTimerState(); // Retry loading
                },
              ),
            ),
          );
          return;
        }
      }

      if (wasTiming && savedStartTime != null) {
        startTime = DateTime.parse(savedStartTime);
        checkInTime = savedCheckInTime != null
            ? DateTime.parse(savedCheckInTime)
            : startTime;
        isTiming = true;
        _startTimer();

        // Check if there's a checkout time for today
        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        final User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          final String currentDate =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          final docRef = firestore
              .collection('attendance')
              .doc(currentUser.uid)
              .collection('dates')
              .doc(currentDate);

          DocumentSnapshot doc = await docRef.get();

          if (doc.exists) {
            Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              if (data.containsKey('checkOutTime') &&
                  data['checkOutTime'] != null) {
                // Already checked out today
                isTiming = false;

                if (data.containsKey('checkInTime') &&
                    data['checkInTime'] != null) {
                  checkInTime = DateTime.parse(data['checkInTime'] as String);
                }

                if (data.containsKey('checkOutTime') &&
                    data['checkOutTime'] != null) {
                  checkOutTime = DateTime.parse(data['checkOutTime'] as String);
                }

                // Calculate elapsed time from stored check-in and check-out times
                if (checkInTime != null && checkOutTime != null) {
                  elapsedTime = checkOutTime!.difference(checkInTime!);
                }
              } else if (data.containsKey('checkInTime') &&
                  data['checkInTime'] != null &&
                  (!data.containsKey('checkOutTime') ||
                      data['checkOutTime'] == null)) {
                // Checked in but not out
                checkInTime = DateTime.parse(data['checkInTime'] as String);
                startTime = checkInTime;
                isTiming = true;
                _startTimer();
              }
            }
          }
        } else {
          print("User became null during Firestore access");
        }
      } else {
        // Check if there's a record for today even if we didn't have saved timer state
        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        final User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          final String currentDate =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          final docRef = firestore
              .collection('attendance')
              .doc(currentUser.uid)
              .collection('dates')
              .doc(currentDate);

          DocumentSnapshot doc = await docRef.get();

          if (doc.exists) {
            Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              if (data.containsKey('checkOutTime') &&
                  data['checkOutTime'] != null) {
                // Already checked out today
                isTiming = false;

                if (data.containsKey('checkInTime') &&
                    data['checkInTime'] != null) {
                  checkInTime = DateTime.parse(data['checkInTime'] as String);
                }

                if (data.containsKey('checkOutTime') &&
                    data['checkOutTime'] != null) {
                  checkOutTime = DateTime.parse(data['checkOutTime'] as String);
                }

                // Calculate elapsed time from stored check-in and check-out times
                if (checkInTime != null && checkOutTime != null) {
                  elapsedTime = checkOutTime!.difference(checkInTime!);
                }
              } else if (data.containsKey('checkInTime') &&
                  data['checkInTime'] != null) {
                // Checked in but not out
                checkInTime = DateTime.parse(data['checkInTime'] as String);
                startTime = checkInTime;
                isTiming = true;
                _startTimer();
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error loading timer state: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading attendance data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  /// Save timer state persistently
  Future<void> _saveTimerState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isTiming', isTiming);
    if (startTime != null) {
      prefs.setString('startTime', startTime!.toIso8601String());
    } else {
      prefs.remove('startTime');
    }

    if (checkInTime != null) {
      prefs.setString('checkInTime', checkInTime!.toIso8601String());
    } else {
      prefs.remove('checkInTime');
    }
  }

  /// Fingerprint Authentication & Timer Control
  Future<void> _scanFingerprint() async {
    if (isLoading) return; // Prevent multiple attempts while processing

    setState(() {
      isLoading = true;
    });

    bool isAuthenticated = false;

    try {
      isAuthenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to mark attendance',
        options: AuthenticationOptions(biometricOnly: true),
      );

      if (isAuthenticated) {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        final User? user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          print("User is not logged in");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ User not logged in"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }

        final String userUid = user.uid;
        final DateTime now = DateTime.now();
        final String currentDate = DateFormat('yyyy-MM-dd').format(now);

        // Fetch the user's name from the users collection
        DocumentSnapshot userDoc =
            await firestore.collection('users').doc(userUid).get();
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        String? userName = userData?['name'];

        if (userName == null) {
          print("User name not found in Firestore");
          // Use email if name is not available
          userName = user.email ?? "Unknown User";
        }

        if (!isTiming) {
          // Clocking In
          startTime = now;
          checkInTime = startTime;
          elapsedTime = Duration(seconds: 0);
          _startTimer();

          // Save to Firestore - check-in only
          await firestore
              .collection('attendance')
              .doc(userUid)
              .collection('dates')
              .doc(currentDate)
              .set({
            'name': userName,
            'checkInTime': checkInTime?.toIso8601String(),
            'currentDate': currentDate,
            'status': 'checked-in',
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Check-In Successful!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Clocking Out
          checkOutTime = now;
          _stopTimer();

          // Calculate hours, minutes, and seconds
          int hours = elapsedTime.inHours;
          int minutes = (elapsedTime.inMinutes % 60);
          int seconds = (elapsedTime.inSeconds % 60);

          // Format as strings with leading zeros
          String hoursStr = hours.toString().padLeft(2, '0');
          String minutesStr = minutes.toString().padLeft(2, '0');
          String secondsStr = seconds.toString().padLeft(2, '0');

          // Save complete data to Firestore
          await firestore
              .collection('attendance')
              .doc(userUid)
              .collection('dates')
              .doc(currentDate)
              .set({
            'name': userName,
            'checkInTime': checkInTime?.toIso8601String(),
            'checkOutTime': checkOutTime?.toIso8601String(),
            'formattedTime': "$hoursStr'hrs':$minutesStr'min':$secondsStr'sec'",
            'currentDate': currentDate,
            'status': 'checked-out',
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Check-Out Successful!"),
              backgroundColor: Colors.green,
            ),
          );
        }

        setState(() {
          isTiming = !isTiming;
          isLoading = false;
        });

        _saveTimerState();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Authentication Failed!"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Start Timer
  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (startTime != null) {
        setState(() {
          elapsedTime = DateTime.now().difference(startTime!);
        });
      }
    });
  }

  /// Stop Timer
  void _stopTimer() {
    _timer?.cancel();
    _saveTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _scanFingerprint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoading
                        ? Colors.grey
                        : (isTiming ? Colors.red : Colors.green.shade700),
                    shape: CircleBorder(),
                    elevation: 20,
                    padding: EdgeInsets.all(0),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Icon(isTiming ? Icons.logout : Icons.fingerprint,
                          size: 60, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),

              // Status Text
              Text(
                isTiming ? "Currently Checked In" : "Ready to Check In",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isTiming ? Colors.green : Colors.black87,
                ),
              ),
              SizedBox(height: 10),

              // Display Timer
              Text(
                isTiming
                    ? "Elapsed Time: ${elapsedTime.inHours.toString().padLeft(2, '0')}:"
                        "${(elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:"
                        "${(elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}"
                    : startTime != null
                        ? "Total Time: ${elapsedTime.inHours.toString().padLeft(2, '0')}:"
                            "${(elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:"
                            "${(elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}"
                        : "Press the button to start",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Display Check-in and Check-out Times
              if (checkInTime != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(Icons.login, color: Colors.green),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Check-in",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd').format(checkInTime!),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            Text(
                              DateFormat('HH:mm:ss').format(checkInTime!),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (checkOutTime != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  color: Colors.grey[50],
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Check-out",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd').format(checkOutTime!),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            Text(
                              DateFormat('HH:mm:ss').format(checkOutTime!),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool showPreviousYear = false;

  Map<String, Map<String, dynamic>> currentYearPayments = {};
  Map<String, Map<String, dynamic>> previousYearPayments = {};

  bool isLoading = true; // <-- Add loading flag

  @override
  void initState() {
    super.initState();
    _fetchSalaries();
  }

  Future<void> _fetchSalaries() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final currentYear = DateTime.now().year.toString();
      final previousYear = (DateTime.now().year - 1).toString();

      await _fetchYearSalary(currentYear, currentYearPayments, currentUser.uid);
      await _fetchYearSalary(
          previousYear, previousYearPayments, currentUser.uid);
    } catch (e) {
      print('Error fetching salaries: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchYearSalary(
    String year,
    Map<String, Map<String, dynamic>> paymentsMap,
    String uid,
  ) async {
    final yearDocRef =
        FirebaseFirestore.instance.collection('salary_records').doc(year);
    final months = [
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

    for (var month in months) {
      try {
        final monthCollection = yearDocRef.collection(month);
        final querySnapshot =
            await monthCollection.where('empId', isEqualTo: uid).get();

        if (querySnapshot.docs.isNotEmpty) {
          final docData = querySnapshot.docs.first.data();
          paymentsMap[month] = {
            'month': docData['month'] ?? month,
            'amount': int.tryParse(docData['salary'].toString()) ?? 0,
            'status':
                (docData['status'] ?? '').toString().toLowerCase() == 'paid',
          };
        } else {
          // No document found — optionally handle
          paymentsMap[month] = {
            'month': month,
            'amount': 0,
            'status': false,
          };
        }
      } catch (e) {
        print('Error fetching month $month for $year: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Payments",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildYearSection(
                            "Current Year (${DateTime.now().year})",
                            currentYearPayments.values.toList()),
                        SizedBox(height: 16),
                        if (showPreviousYear)
                          _buildYearSection(
                              "Previous Year (${DateTime.now().year - 1})",
                              previousYearPayments.values.toList()),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showPreviousYear = !showPreviousYear;
                        });
                      },
                      child: Text(showPreviousYear
                          ? "Hide Previous Year"
                          : "Show Previous Year"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildYearSection(String title, List<Map<String, dynamic>> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _buildPaymentCard(
              month: payment['month'] ?? '',
              amount: payment['amount'] ?? 0,
              isPaid: payment['status'] ?? false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required String month,
    required int amount,
    required bool isPaid,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            month,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              Text(
                "₹$amount",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Text(
                isPaid ? "Paid" : "Not Paid",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isPaid ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
        .collection("users")
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
          .collection("users")
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
          .collection("users")
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
                        "${userData?["name"] ?? "Unknown"}",
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
                          userData?["email"] ?? "No email provided",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      _buildInfoSection("Personal Info", [
                        _buildInfoRow(
                            "Qualification", userData!["qualification"]),
                        _buildInfoRow("Experience", userData!["experience"]),
                        _buildInfoRow("Age", userData!["age"]),
                        _buildInfoRow("Date Of Birth", userData!["dob"]),
                        _buildInfoRow("Whatsapp Number", userData!["whatsapp"]),
                        _buildInfoRow("Mobile", userData!["mobile"]),
                        _buildInfoRow(
                            "Alternate Mobile", userData!["altMobile"]),
                        _buildInfoRow(
                            "Emergency Contact", userData!["emergencyContact"]),
                        _buildInfoRow("Blood Group", userData!["bloodGroup"]),
                        _buildInfoRow("Gender", userData!["gender"]),
                        _buildInfoRow("Father Name", userData!["fatherName"]),
                        _buildInfoRow(
                            "Father Mobile", userData!["fatherMobile"]),
                        _buildInfoRow("Mother Name", userData!["motherName"]),
                        _buildInfoRow(
                            "Mother Mobile", userData!["motherMobile"]),
                        _buildInfoRow("Spouse Name", userData!["spouseName"]),
                        _buildInfoRow(
                            "Spouse Mobile", userData!["spouseMobile"]),
                      ]),
                      _buildInfoSection2("Address Details", [
                        _buildInfoRow("Address", userData!["address"]),
                        _buildInfoRow("District", userData!["district"]),
                        _buildInfoRow("State", userData!["state"]),
                        _buildInfoRow("Pincode", userData!["pincode"]),
                        _buildInfoRow("Native Place", userData!["native"]),
                      ]),
                      _buildInfoSection2("Bank Details", [
                        _buildInfoRow("Bank Name", userData!["bank_name"]),
                        _buildInfoRow(
                            "Account Number", userData!["account_number"]),
                        _buildInfoRow(
                            "Account Holder Name", userData!["account_holder"]),
                        _buildInfoRow("IFSC Code", userData!["ifsc"]),
                      ]),
                      _buildInfoSection2("Additional info", [
                        _buildInfoRow("Aadhar Number", userData!["aadhar"]),
                        _buildInfoRow("EPF Number", userData!["epf"]),
                        _buildInfoRow("ESI Number", userData!["esi"]),
                        _buildInfoRow("IFSC Number", userData!["ifsc"]),
                        _buildInfoRow("PAN Number", userData!["pan"]),
                        _buildInfoRow("Religion", userData!["religion"]),
                        _buildInfoRow("Cast", userData!["cast"]),
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

  Widget _buildInfoSection2(String title, List<Widget> children) {
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
    final isAddressOrAccount = title.toLowerCase().contains('address') ||
        title.toLowerCase().contains('account number');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: isAddressOrAccount
                ? Text(
                    value ?? "Not provided",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[900],
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                  )
                : Text(
                    value ?? "Not provided",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[900],
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: null,
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

  const EditProfilePage({super.key, required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: TextEditingController(text: userData["name"]),
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: TextEditingController(text: userData["email"]),
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: TextEditingController(text: userData["mobile"]),
              decoration: InputDecoration(labelText: "Phone Number"),
            ),
            TextField(
              controller: TextEditingController(text: userData["whatsapp"]),
              decoration: InputDecoration(labelText: "Whatsapp Number"),
            ),
            TextField(
              controller: TextEditingController(text: userData["altMobile"]),
              decoration: InputDecoration(labelText: "Alternate Mobile"),
            ),
            TextField(
              controller:
                  TextEditingController(text: userData["emergencyContact"]),
              decoration: InputDecoration(labelText: "Emergency Contact"),
            ),
            TextField(
              controller: TextEditingController(text: userData["experience"]),
              decoration: InputDecoration(labelText: "Experience"),
            ),
            TextField(
              controller:
                  TextEditingController(text: userData["qualification"]),
              decoration: InputDecoration(labelText: "Qualification"),
            ),
            TextField(
              controller: TextEditingController(text: userData["dob"]),
              decoration: InputDecoration(labelText: "Date of Birth"),
            ),
            TextField(
              controller:
                  TextEditingController(text: userData["age"]?.toString()),
              decoration: InputDecoration(labelText: "Age"),
            ),
            TextField(
              controller: TextEditingController(text: userData["gender"]),
              decoration: InputDecoration(labelText: "Gender"),
            ),
            TextField(
              controller: TextEditingController(text: userData["bloodGroup"]),
              decoration: InputDecoration(labelText: "Blood Group"),
            ),
            TextField(
              controller: TextEditingController(text: userData["fatherName"]),
              decoration: InputDecoration(labelText: "FatherName"),
            ),
            TextField(
              controller: TextEditingController(text: userData["fatherMobile"]),
              decoration: InputDecoration(labelText: "Father Mobile"),
            ),
            TextField(
              controller: TextEditingController(text: userData["motherName"]),
              decoration: InputDecoration(labelText: "Mother Name"),
            ),
            TextField(
              controller: TextEditingController(text: userData["motherMobile"]),
              decoration: InputDecoration(labelText: "Mother Mobile"),
            ),
            TextField(
              controller: TextEditingController(text: userData["spouseName"]),
              decoration: InputDecoration(labelText: "Spouse Name"),
            ),
            TextField(
              controller: TextEditingController(text: userData["spouseMobile"]),
              decoration: InputDecoration(labelText: "Spouse Mobile"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle form submission
              },
              child: Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
