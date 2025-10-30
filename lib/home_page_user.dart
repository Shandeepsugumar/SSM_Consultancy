import 'dart:convert';
import 'dart:io';
import 'package:consultancy/loginpage.dart';
import 'package:consultancy/models/schedule_model.dart';
import 'package:consultancy/services/schedule_service.dart';
import 'package:consultancy/session_manager.dart';
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

  // Create key to force refresh of HomeScreen
  final GlobalKey<_HomeScreenState> _homeScreenKey =
      GlobalKey<_HomeScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(key: _homeScreenKey, onNavigationTap: _onItemTapped),
      SchedulePage(),
      AttendanceScreen(),
      // AccountsScreen(),
      ProfilePage(showAppBar: false), // Don't show AppBar when in bottom nav
    ];
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
      // Get user data from SessionManager to get the correct custom UID
      String? currentUserUid = await SessionManager.getCurrentUserUid();
      Map<String, dynamic>? currentUserData =
          await SessionManager.getCurrentUserData();

      if (currentUserUid == null || currentUserData == null) {
        print('No user data found in SessionManager, skipping location update');
        return;
      }

      // Ensure UID mapping exists for Firebase Auth
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await _ensureUidMapping(firebaseUser.uid, currentUserUid);
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

      String userName = currentUserData['name'] ?? 'Unknown';
      String? eid =
          currentUserData['Eid']; // Get the Eid field from users collection
      String email = currentUserData['email'] ?? '';
      String mobile = currentUserData['mobile'] ?? '';

      print(
          'Location update - User: $userName, Eid: $eid, Custom UID: $currentUserUid');

      // Use custom UID as document ID for live_locations
      final String liveDocId = currentUserUid;

      await FirebaseFirestore.instance
          .collection('live_locations')
          .doc(liveDocId)
          .set({
        'employeeId': currentUserUid, // Store the custom employee ID
        'Eid': eid, // Store the Eid field from users collection
        'name': userName, // Store the actual employee name
        'email': email,
        'mobile': mobile,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdate': DateTime.now().toIso8601String(),
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'status': 'active', // Indicates this was updated from foreground
      }, SetOptions(merge: true));

      setState(() {
        _lastLocationUpdate = DateTime.now();
      });

      print('✅ Location updated successfully at ${DateTime.now()}');
      print(
          '📍 Latitude: ${position.latitude}, Longitude: ${position.longitude}');
      print(
          '👤 Stored data - Name: $userName, Eid: $eid, Custom UID: $currentUserUid');
      print('🔗 Document ID in live_locations: $currentUserUid');
      print('🔐 Firebase Auth UID: ${firebaseUser?.uid}');
      print('📊 Location data stored with status: active');
    } catch (e) {
      print('Error sending location: $e');
    }
  }

  /// Ensure uid_mapping document exists for the current user
  Future<void> _ensureUidMapping(String firebaseUid, String customUid) async {
    try {
      final mappingDoc = await FirebaseFirestore.instance
          .collection('uid_mapping')
          .doc(firebaseUid)
          .get();

      if (!mappingDoc.exists) {
        print(
            '🔗 Creating uid_mapping for Firebase UID: $firebaseUid -> Custom UID: $customUid');
        await FirebaseFirestore.instance
            .collection('uid_mapping')
            .doc(firebaseUid)
            .set({
          'originalAuthUid': firebaseUid,
          'customUid': customUid,
          'createdAt': DateTime.now(),
        });
        print('✅ UID mapping created successfully');
      } else {
        print('✅ UID mapping already exists');
      }
    } catch (e) {
      print('❌ Error ensuring UID mapping: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Refresh HomeScreen data when it's selected
    if (index == 0) {
      Future.delayed(Duration(milliseconds: 100), () {
        _homeScreenKey.currentState?.refreshData();
      });
    }
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
          // Show logout button when profile page is selected
          if (_selectedIndex == 3)
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () => _handleHomePageLogout(context),
              tooltip: 'Logout',
            ),
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
        return "PROFILE";
      default:
        return "Welcome To SSM";
    }
  }

  void _handleHomePageLogout(BuildContext context) async {
    // Show confirmation dialog
    bool shouldLogout = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text(
                    'Logging out...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Clear SessionManager data
      await SessionManager.clearUserSession();
      print('SessionManager logout completed');

      // Sign out from Firebase Auth
      try {
        await FirebaseAuth.instance.signOut();
        print('Firebase Auth logout completed');
      } catch (firebaseError) {
        print('Firebase logout error (continuing anyway): $firebaseError');
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to login page and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false, // This will remove all routes from the stack
      );
    } catch (e) {
      print('Error during logout: $e');
      // Close loading dialog if still open
      Navigator.of(context).pop();
      // Still navigate to login page even if there was an error
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }
}

// Screens
class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigationTap;

  const HomeScreen({super.key, this.onNavigationTap});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<_DashboardPageState> _dashboardKey =
      GlobalKey<_DashboardPageState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: DashboardPage(
          key: _dashboardKey, onNavigationTap: widget.onNavigationTap),
    );
  }

  // Method to refresh the dashboard data
  void refreshData() {
    _dashboardKey.currentState?.fetchUserName();
  }
}

// Dashboard Widget with Firebase Name Fetching
class DashboardPage extends StatefulWidget {
  final Function(int)? onNavigationTap;

  const DashboardPage({super.key, this.onNavigationTap});

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
    try {
      // Use SessionManager to get the custom UID instead of Firebase UID
      String? customUid = await SessionManager.getCurrentUserUid();
      if (customUid == null) {
        print('No custom UID found in session');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Fetching user data for custom UID: $customUid');

      // Fetch user data using the custom UID (like SSM023)
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(customUid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> fetchedUserData =
            doc.data() as Map<String, dynamic>;
        print('User data fetched successfully: ${fetchedUserData['name']}');

        setState(() {
          userData = fetchedUserData;
          _profileImageUrl = userData!["profileImageUrl"];

          // Check for the new 'profilephoto' field first, then fallback to old field
          _profilePicBinary =
              userData!["profilephoto"] ?? userData!["profilePicBinary"];

          if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
            try {
              _profileImageBytes = base64Decode(_profilePicBinary!);
              print("Successfully loaded profile photo from Firestore");
            } catch (e) {
              print("Error decoding base64: $e");
            }
          }
          _isLoading = false;
        });
      } else {
        print('User document not found for UID: $customUid');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileSection(),
                SizedBox(height: 16),
                _buildQuickAccessSection(),
                SizedBox(height: 16), // Bottom padding for better scrolling
              ],
            ),
          );
  }

  Widget _buildProfileSection() {
    if (userData == null) {
      return Container(
        padding: EdgeInsets.all(24),
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
        child: Center(
          child: Text(
            "Loading profile...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.blue[700]!],
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
          Stack(
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue[900]!, width: 2),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue[900]!, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                    padding: EdgeInsets.all(6),
                    constraints: BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData!["name"] ?? "Unknown User",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "ID: ${userData!["uid"] ?? "N/A"}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 6),
                if (userData!["qualification"] != null &&
                    userData!["qualification"].toString().isNotEmpty)
                  Text(
                    userData!["qualification"] ?? "Employee",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Container(
      padding: EdgeInsets.all(20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: Colors.blue[900], size: 24),
              SizedBox(width: 8),
              Text(
                "Quick Access",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessItem(
                  _quickAccessItems[0]['icon'],
                  _quickAccessItems[0]['label'],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildQuickAccessItem(
                  _quickAccessItems[1]['icon'],
                  _quickAccessItems[1]['label'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(IconData icon, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (label == "My Attendance" && widget.onNavigationTap != null) {
            // Navigate to attendance tab (index 2)
            widget.onNavigationTap!(2);
          } else if (label == "My Schedule" && widget.onNavigationTap != null) {
            // Navigate to schedule tab (index 1)
            widget.onNavigationTap!(1);
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: BoxConstraints(
            minHeight: 120,
          ),
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[900]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 26, color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _quickAccessItems = [
    {'icon': Icons.calendar_today, 'label': "My Schedule"},
    {'icon': Icons.assignment, 'label': "My Attendance"},
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
  List<ScheduleModel> _userSchedules = [];
  Map<String, UserModel> _usersMap = {};
  final ScheduleService _scheduleService = ScheduleService();
  String? _currentUserUid;
  String? _currentUserEid; // Store current user's Eid for schedule filtering

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
      print('🔍 SCHEDULE DEBUG: Starting _loadScheduleData...');

      // Use SessionManager to get current user UID and data
      final currentUserUid = await SessionManager.getCurrentUserUid();
      if (currentUserUid == null) {
        print('❌ SCHEDULE DEBUG: No current user UID found');
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not authenticated';
        });
        return;
      }
      print('✅ SCHEDULE DEBUG: Current user UID: $currentUserUid');

      // Get current user's data to extract Eid
      Map<String, dynamic>? currentUserData =
          await SessionManager.getCurrentUserData();
      if (currentUserData == null) {
        print(
            '⚠️ SCHEDULE DEBUG: No cached user data, fetching from Firestore...');
        // If cached data is not available, fetch from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(currentUserUid)
            .get();

        if (!userDoc.exists) {
          print('❌ SCHEDULE DEBUG: User document does not exist in Firestore');
          setState(() {
            _isLoading = false;
            _errorMessage = 'User data not found';
          });
          return;
        }
        currentUserData = userDoc.data() as Map<String, dynamic>;
        print(
            '✅ SCHEDULE DEBUG: Fetched user data from Firestore: ${currentUserData.keys.toList()}');
      } else {
        print(
            '✅ SCHEDULE DEBUG: Using cached user data: ${currentUserData.keys.toList()}');
      }

      // Extract Eid from user data
      String? currentUserEid = currentUserData['Eid'];
      if (currentUserEid == null || currentUserEid.isEmpty) {
        final availableFields = currentUserData.keys.toList();
        final eidValue = currentUserData['Eid'];
        print(
            '❌ SCHEDULE DEBUG: No Eid found in user data. Available fields: $availableFields');
        print('❌ SCHEDULE DEBUG: Eid field value: $eidValue');
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Employee ID (Eid) not found in user data. Available fields: $availableFields';
        });
        return;
      }

      print('✅ SCHEDULE DEBUG: Current user Eid: $currentUserEid');

      // Call schedule service to get data
      print('🔍 SCHEDULE DEBUG: Calling refreshScheduleData...');
      final data = await _scheduleService.refreshScheduleData();

      final allSchedules = data['schedules'] as List<ScheduleModel>;
      final usersMap = data['usersMap'] as Map<String, UserModel>;

      print(
          '✅ SCHEDULE DEBUG: Retrieved ${allSchedules.length} total schedules from service');
      print('✅ SCHEDULE DEBUG: Retrieved ${usersMap.length} user records');

      // Debug: Show some sample schedule data
      if (allSchedules.isNotEmpty) {
        final firstSchedule = allSchedules.first;
        print('📋 SCHEDULE DEBUG: Sample schedule:');
        print('   - ID: ${firstSchedule.id}');
        print('   - Branch: ${firstSchedule.branchName}');
        print('   - Assigned Employees: ${firstSchedule.assignedEmployees}');
        print('   - Start Date: ${firstSchedule.startDate}');
        print('   - End Date: ${firstSchedule.endDate}');
        print('   - Status: ${firstSchedule.status}');
      }

      // Filter schedules for current user by checking if their Eid is in assignedEmployees
      final userSchedules = allSchedules.where((schedule) {
        final isAssigned = schedule.assignedEmployees.contains(currentUserEid);
        if (isAssigned) {
          print(
              '✅ SCHEDULE DEBUG: Found matching schedule ${schedule.id} for Eid $currentUserEid');
        }
        return isAssigned;
      }).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      print(
          '✅ SCHEDULE DEBUG: Filtered ${userSchedules.length} schedules for Eid: $currentUserEid');

      // Debug: If no schedules found, show all assignedEmployees arrays for debugging
      if (userSchedules.isEmpty && allSchedules.isNotEmpty) {
        print(
            '⚠️ SCHEDULE DEBUG: No schedules found for current user. Checking all assignedEmployees arrays:');
        for (int i = 0; i < allSchedules.length && i < 5; i++) {
          final schedule = allSchedules[i];
          print(
              '   Schedule ${schedule.id}: assignedEmployees = ${schedule.assignedEmployees}');
        }
        print(
            '🔍 SCHEDULE DEBUG: Looking for Eid: "$currentUserEid" (length: ${currentUserEid.length})');
      }

      setState(() {
        _currentUserUid = currentUserUid;
        _currentUserEid = currentUserEid; // Store Eid for filtering
        _allSchedules = allSchedules;
        _usersMap = usersMap;
        _userSchedules = userSchedules;
        _isLoading = false;
      });

      print('✅ SCHEDULE DEBUG: _loadScheduleData completed successfully');
    } catch (e, stackTrace) {
      print('❌ SCHEDULE DEBUG: Error in _loadScheduleData: $e');
      print('❌ SCHEDULE DEBUG: Stack trace: $stackTrace');

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
    // Use the already filtered _userSchedules
    return _userSchedules.where((schedule) {
      return schedule.isScheduledForDate(_selectedDate);
    }).toList();
  }

  List<ScheduleModel> getAllUserSchedules() {
    return _userSchedules;
  }

  bool _isScheduledDay(DateTime date) {
    return _userSchedules.any((schedule) {
      return schedule.isScheduledForDate(date);
    });
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
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            SizedBox(height: 16),
            Text(
              'Loading schedules...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Action buttons row
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _showAllSchedules
                          ? Colors.blue.shade700
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.list,
                        color: _showAllSchedules
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                      onPressed: () {
                        setState(() {
                          _showAllSchedules = true;
                        });
                      },
                      tooltip: 'Show all schedules',
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: !_showAllSchedules
                          ? Colors.blue.shade700
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.calendar_today,
                        color: !_showAllSchedules
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                      onPressed: () {
                        setState(() {
                          _showAllSchedules = false;
                        });
                      },
                      tooltip: 'Show date schedules',
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.blue.shade700,
                      ),
                      onPressed: _loadScheduleData,
                      tooltip: 'Refresh',
                    ),
                  ),
                ],
              ),
            ),
            _buildMonthNavigation(),
            _buildWeekDays(),
            _buildCalendar(),
            SizedBox(height: 8),
            _buildScheduleHeader(),
            _buildScrollableScheduleList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _goToPreviousMonth,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat.yMMMM().format(_focusedDate),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _goToNextMonth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: days
            .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
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
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.shade700
                  : hasSchedule
                      ? Colors.green.shade50
                      : Colors.white,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.blue.shade700, width: 3)
                  : hasSchedule
                      ? Border.all(color: Colors.green.shade300, width: 2)
                      : Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : hasSchedule
                                ? Colors.green.shade700
                                : Colors.black87,
                        fontWeight: isSelected || hasSchedule
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    if (hasSchedule && !isSelected)
                      Container(
                        margin: EdgeInsets.only(top: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: dayWidgets,
      ),
    );
  }

  Widget _buildScheduleHeader() {
    final scheduleCount = _showAllSchedules
        ? getAllUserSchedules().length
        : getSchedulesForSelectedDate().length;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _showAllSchedules ? Icons.list : Icons.calendar_today,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showAllSchedules
                      ? 'All My Schedules'
                      : 'Schedules for ${DateFormat.yMMMMd().format(_selectedDate)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '$scheduleCount ${scheduleCount == 1 ? 'schedule' : 'schedules'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (!_showAllSchedules)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollableScheduleList() {
    // Choose which schedules to show based on toggle
    final schedules = _showAllSchedules
        ? getAllUserSchedules()
        : getSchedulesForSelectedDate();

    if (_isLoading) {
      return Container(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 64, color: Colors.red.shade700),
            ),
            SizedBox(height: 24),
            Text(
              'Error loading schedules',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadScheduleData,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (schedules.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade100,
                    Colors.blue.shade50,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 24),
            Text(
              _showAllSchedules
                  ? 'No Work Schedules'
                  : 'No Schedule for This Date',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              _showAllSchedules
                  ? 'No work schedules found for your account yet.'
                  : 'No work scheduled for ${DateFormat.yMMMMd().format(_selectedDate)}',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (_showAllSchedules) ...[
              SizedBox(height: 8),
              Text(
                'Contact your administrator if you believe this is an error',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: schedules.map((schedule) {
        final assignedEmployeeNames =
            _scheduleService.getAssignedEmployeeNames(schedule, _usersMap);
        final isAssignedToCurrentUser = _currentUserEid != null &&
            schedule.assignedEmployees.contains(_currentUserEid);

        // Calculate remaining workers needed
        final remainingWorkers =
            schedule.numberOfWorkers - schedule.assignedEmployees.length;

        return Container(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.blue.shade100,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Branch Name and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade600,
                                  Colors.blue.shade700,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.business,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schedule.branchName.isEmpty
                                      ? 'Unknown Branch'
                                      : schedule.branchName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isAssignedToCurrentUser)
                                  Container(
                                    margin: EdgeInsets.only(top: 4),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade400,
                                          Colors.green.shade500,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'ASSIGNED TO YOU',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(schedule.getDisplayStatus()),
                            _getStatusColor(schedule.getDisplayStatus())
                                .withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(schedule.getDisplayStatus())
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        schedule.getDisplayStatus(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Work Period
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade100.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Work Period',
                        '${_formatScheduleDate(schedule.startDate)} - ${_formatScheduleDate(schedule.endDate)}',
                        Colors.blue.shade700,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailRow(
                              Icons.access_time,
                              'Start Time',
                              schedule.startTime.isEmpty
                                  ? 'Not set'
                                  : schedule.startTime,
                              Colors.green.shade700,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailRow(
                              Icons.access_time_filled,
                              'End Time',
                              schedule.endTime.isEmpty
                                  ? 'Not set'
                                  : schedule.endTime,
                              Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.hourglass_top,
                        'Total Hours',
                        '${schedule.totalHours} hours',
                        Colors.purple.shade700,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Worker Information
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade50,
                        Colors.orange.shade100.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailRow(
                              Icons.people,
                              'Workers Needed',
                              '${schedule.numberOfWorkers}',
                              Colors.orange.shade700,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailRow(
                              Icons.people_outline,
                              'Assigned',
                              '${schedule.assignedEmployees.length}',
                              Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (remainingWorkers > 0) ...[
                        SizedBox(height: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning,
                                  color: Colors.red.shade700, size: 18),
                              SizedBox(width: 8),
                              Text(
                                '$remainingWorkers more worker${remainingWorkers > 1 ? 's' : ''} needed',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (remainingWorkers == 0) ...[
                        SizedBox(height: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade700, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Fully staffed',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Assigned Workers List
                if (assignedEmployeeNames.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.groups,
                                color: Colors.grey.shade700, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Assigned Workers:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: assignedEmployeeNames
                              .asMap()
                              .entries
                              .map((entry) {
                            int index = entry.key;
                            String name = entry.value;
                            // Check if the Eid at this index matches current user's Eid
                            bool isCurrentUser = _currentUserEid != null &&
                                index < schedule.assignedEmployees.length &&
                                schedule.assignedEmployees[index] ==
                                    _currentUserEid;
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.blue.shade100
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrentUser
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade400,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCurrentUser) ...[
                                    Icon(Icons.person,
                                        size: 16, color: Colors.blue.shade700),
                                    SizedBox(width: 4),
                                  ],
                                  Text(
                                    isCurrentUser ? 'You' : name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isCurrentUser
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade700,
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Expired Warning
                if (schedule.isExpired()) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning,
                            color: Colors.red.shade700, size: 20),
                        SizedBox(width: 12),
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
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
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
  String? attendanceStatus;

  /// Calculate attendance status based on work hours
  String _calculateAttendanceStatus(Duration workDuration) {
    // Convert duration to total hours (including decimal for minutes)
    double totalHours = workDuration.inMinutes / 60.0;

    print(
        '📊 Calculating attendance status for ${totalHours.toStringAsFixed(2)} hours');

    if (totalHours < 2.0) {
      // Less than 2 hours = Absent
      return 'absent';
    } else if (totalHours >= 2.0 && totalHours < 8.5) {
      // 2 hours to less than 8.5 hours = Half day present
      return 'halfday present';
    } else if (totalHours >= 8.5 && totalHours <= 8.6) {
      // 8.5 to 8.6 hours = Full day present (allowing small margin)
      return 'present';
    } else {
      // More than 8.5 hours = Present + extra hours
      double extraHours = totalHours - 8.5;
      int extraHoursInt = extraHours.floor();
      int extraMinutes = ((extraHours - extraHoursInt) * 60).round();

      if (extraMinutes > 0) {
        return 'present + ${extraHoursInt}hrs ${extraMinutes}min extra work';
      } else {
        return 'present + ${extraHoursInt}hrs extra work';
      }
    }
  }

  /// Ensure uid_mapping document exists for the current user
  Future<void> _ensureUidMapping(String firebaseUid, String customUid) async {
    try {
      final mappingDoc = await FirebaseFirestore.instance
          .collection('uid_mapping')
          .doc(firebaseUid)
          .get();

      if (!mappingDoc.exists) {
        print(
            '🔗 Creating uid_mapping for Firebase UID: $firebaseUid -> Custom UID: $customUid');
        await FirebaseFirestore.instance
            .collection('uid_mapping')
            .doc(firebaseUid)
            .set({
          'originalAuthUid': firebaseUid,
          'customUid': customUid,
          'createdAt': DateTime.now(),
        });
        print('✅ UID mapping created successfully');
      } else {
        print('✅ UID mapping already exists');
      }
    } catch (e) {
      print('❌ Error ensuring UID mapping: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTimerState(); // Load the previous timer state if exists
    _initializeFirebaseAuthForAttendance(); // Initialize Firebase Auth for attendance
  }

  /// Initialize Firebase Auth specifically for attendance functionality
  Future<void> _initializeFirebaseAuthForAttendance() async {
    try {
      // Check if user is already signed in to Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print(
            '✅ Firebase user already authenticated for attendance: ${user.uid}');
        return;
      }

      // Get current user from SessionManager
      final currentUserUid = await SessionManager.getCurrentUserUid();
      final currentUserData = await SessionManager.getCurrentUserData();

      if (currentUserUid == null || currentUserData == null) {
        print('❌ No user in SessionManager for attendance Firebase Auth');
        return;
      }

      print('🔐 Initializing Firebase Auth for attendance: $currentUserUid');

      // Use the actual user email from SessionManager data instead of creating a fake one
      final userEmail = currentUserData['email'];
      if (userEmail == null || userEmail.isEmpty) {
        print('❌ No email found in user data, cannot initialize Firebase Auth');
        return;
      }

      // Try to sign in with the actual user email
      try {
        print(
            '🔑 Attempting Firebase signIn for attendance with email: $userEmail');

        // Try to sign in with the actual email
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmail,
          password: currentUserData['password'] ??
              currentUserUid, // Use stored password or UID as fallback
        );
        print(
            '✅ Firebase signIn successful for attendance: ${credential.user?.uid}');

        // Ensure uid_mapping document exists
        if (credential.user != null) {
          await _ensureUidMapping(credential.user!.uid, currentUserUid);
        }
      } catch (signInError) {
        print('❌ SignIn failed for attendance: $signInError');
        print(
            '❌ Cannot create new Firebase Auth user - user should already exist from login');
        // Don't create new users here - they should already exist from the login process
      }
    } catch (e) {
      print('❌ Error initializing Firebase Auth for attendance: $e');
    }
  }

  /// Load previous timer state
  Future<void> _loadTimerState() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool wasTiming = prefs.getBool('isTiming') ?? false;
      String? savedStartTime = prefs.getString('startTime');
      String? savedCheckInTime = prefs.getString('checkInTime');

      // First check if user is logged in using session manager
      bool isLoggedIn = await SessionManager.isUserLoggedIn();
      if (!isLoggedIn) {
        print("User is not logged in during _loadTimerState");
        setState(() {
          isLoading = false;
        });

        // Wait a moment and try again - sometimes authentication takes a moment to initialize
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

        // Get current user from session manager
        Map<String, dynamic>? currentUserData =
            await SessionManager.getCurrentUserData();

        if (currentUserData != null) {
          // Get current user UID from SessionManager for attendance document ID
          String? currentUserUid = await SessionManager.getCurrentUserUid();
          if (currentUserUid == null) {
            print("No user UID found while loading timer state");
            return;
          }

          // Debug: Check Firebase Auth status
          final firebaseUser = FirebaseAuth.instance.currentUser;
          print("🔍 Debug - Firebase User: ${firebaseUser?.uid}");
          print("🔍 Debug - Custom User UID: $currentUserUid");
          print("🔍 Debug - User authenticated: ${firebaseUser != null}");

          final String currentDate =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          print(
              "🔍 Debug - Attempting to access: attendance/$currentUserUid/dates/$currentDate");

          final docRef = firestore
              .collection('attendance')
              .doc(currentUserUid)
              .collection('dates')
              .doc(currentDate);

          DocumentSnapshot doc;
          try {
            doc = await docRef.get();
          } catch (e) {
            print("❌ Error accessing attendance document: $e");
            // If permission denied, try to create the uid_mapping document
            if (e.toString().contains('permission-denied')) {
              print(
                  "🔧 Attempting to fix permission issue by creating uid_mapping...");
              await _ensureUidMapping(firebaseUser!.uid, currentUserUid);
              // Retry the operation
              try {
                doc = await docRef.get();
                print("✅ Retry successful after creating uid_mapping");
              } catch (retryError) {
                print("❌ Retry failed: $retryError");
                return;
              }
            } else {
              print("❌ Non-permission error: $e");
              return;
            }
          }

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

                // Load attendance status if available
                if (data.containsKey('attendance_status') &&
                    data['attendance_status'] != null) {
                  attendanceStatus = data['attendance_status'] as String;
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

        // Get current user UID from SessionManager
        String? currentUserUid = await SessionManager.getCurrentUserUid();

        if (currentUserUid != null) {
          final String currentDate =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          final docRef = firestore
              .collection('attendance')
              .doc(currentUserUid)
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

                // Load attendance status if available
                if (data.containsKey('attendance_status') &&
                    data['attendance_status'] != null) {
                  attendanceStatus = data['attendance_status'] as String;
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

        // Get current user from session manager
        String? currentUserUid = await SessionManager.getCurrentUserUid();
        Map<String, dynamic>? currentUserData =
            await SessionManager.getCurrentUserData();

        // Debug: Check Firebase Auth status
        final firebaseUser = FirebaseAuth.instance.currentUser;
        print("🔍 Debug - Firebase User: ${firebaseUser?.uid}");
        print("🔍 Debug - Custom User UID: $currentUserUid");
        print("🔍 Debug - User authenticated: ${firebaseUser != null}");

        if (currentUserUid == null || currentUserData == null) {
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

        final DateTime now = DateTime.now();
        final String currentDate = DateFormat('yyyy-MM-dd').format(now);

        // Use the current user data from session
        String userName = currentUserData['name'] ?? 'Unknown';

        print(
            "🔍 Debug - Attempting to write to: attendance/$currentUserUid/dates/$currentDate");

        if (!isTiming) {
          // Clocking In
          startTime = now;
          checkInTime = startTime;
          elapsedTime = Duration(seconds: 0);
          _startTimer();

          // Save to Firestore - check-in only
          print("🔍 Debug - Writing check-in data...");
          try {
            await firestore
                .collection('attendance')
                .doc(currentUserUid)
                .collection('dates')
                .doc(currentDate)
                .set({
              'name': userName,
              'employeeId': currentUserUid, // Store the custom employee ID
              'Eid': currentUserData[
                  'Eid'], // Store the Eid field from users collection
              'checkInTime': checkInTime?.toIso8601String(),
              'currentDate': currentDate,
              'status': 'checked-in',
            }, SetOptions(merge: true));
          } catch (e) {
            print("❌ Error writing check-in data: $e");
            if (e.toString().contains('permission-denied')) {
              print(
                  "🔧 Attempting to fix permission issue by creating uid_mapping...");
              await _ensureUidMapping(firebaseUser!.uid, currentUserUid);
              // Retry the operation
              try {
                await firestore
                    .collection('attendance')
                    .doc(currentUserUid)
                    .collection('dates')
                    .doc(currentDate)
                    .set({
                  'name': userName,
                  'employeeId': currentUserUid,
                  'checkInTime': checkInTime?.toIso8601String(),
                  'currentDate': currentDate,
                  'status': 'checked-in',
                  'Eid': currentUserData['Eid'],
                }, SetOptions(merge: true));
                print("✅ Retry successful after creating uid_mapping");
              } catch (retryError) {
                print("❌ Retry failed: $retryError");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Check-in failed: $retryError"),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() {
                  isLoading = false;
                });
                return;
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("❌ Check-in failed: $e"),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() {
                isLoading = false;
              });
              return;
            }
          }

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

          // Calculate attendance status based on work duration
          attendanceStatus = _calculateAttendanceStatus(elapsedTime);

          print(
              '📊 Work Duration: ${elapsedTime.inHours}h ${elapsedTime.inMinutes % 60}m');
          print('📊 Attendance Status: $attendanceStatus');

          // Save complete data to Firestore
          await firestore
              .collection('attendance')
              .doc(currentUserUid)
              .collection('dates')
              .doc(currentDate)
              .set({
            'name': userName,
            'employeeId': currentUserUid, // Store the custom employee ID
            'Eid': currentUserData[
                'Eid'], // Store the Eid field from users collection
            'checkInTime': checkInTime?.toIso8601String(),
            'checkOutTime': checkOutTime?.toIso8601String(),
            'formattedTime': "$hoursStr'hrs':$minutesStr'min':$secondsStr'sec'",
            'currentDate': currentDate,
            'status': 'checked-out',
            'attendance_status':
                attendanceStatus, // Store calculated attendance status
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
              // Display Attendance Status
              if (attendanceStatus != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  color: _getAttendanceStatusColor(attendanceStatus!),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(_getAttendanceStatusIcon(attendanceStatus!),
                            color: Colors.white, size: 24),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Attendance Status",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                attendanceStatus!.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _getAttendanceStatusDescription(
                                    attendanceStatus!),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
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

  /// Get color for attendance status
  Color _getAttendanceStatusColor(String status) {
    if (status.contains('absent')) {
      return Colors.red[600]!;
    } else if (status.contains('halfday')) {
      return Colors.orange[600]!;
    } else if (status.contains('extra work')) {
      return Colors.purple[600]!;
    } else if (status.contains('present')) {
      return Colors.green[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  /// Get icon for attendance status
  IconData _getAttendanceStatusIcon(String status) {
    if (status.contains('absent')) {
      return Icons.cancel;
    } else if (status.contains('halfday')) {
      return Icons.schedule;
    } else if (status.contains('extra work')) {
      return Icons.star;
    } else if (status.contains('present')) {
      return Icons.check_circle;
    } else {
      return Icons.help;
    }
  }

  /// Get description for attendance status
  String _getAttendanceStatusDescription(String status) {
    if (status.contains('absent')) {
      return 'Less than 2 hours worked';
    } else if (status.contains('halfday')) {
      return '2-8.5 hours worked';
    } else if (status.contains('extra work')) {
      return 'More than 8.5 hours worked';
    } else if (status.contains('present')) {
      return '8.5 hours worked (Full day)';
    } else {
      return 'Status calculated after check-out';
    }
  }
}

// class AccountsScreen extends StatefulWidget {
//   const AccountsScreen({super.key});

//   @override
//   _AccountsScreenState createState() => _AccountsScreenState();
// }

// class _AccountsScreenState extends State<AccountsScreen> {
//   int selectedYear = DateTime.now().year;
//   Map<String, Map<String, dynamic>> yearlyPayments = {};
//   bool isLoading = true;
//   List<int> availableYears = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeFirebaseAuth();
//   }

//   /// Initialize Firebase Auth to satisfy Firestore security rules
//   Future<void> _initializeFirebaseAuth() async {
//     try {
//       // Check if user is already signed in to Firebase
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         print('✅ Firebase user already authenticated: ${user.uid}');
//         _initializeYears();
//         return;
//       }

//       // Get current user from SessionManager
//       final currentUserUid = await SessionManager.getCurrentUserUid();
//       final currentUserData = await SessionManager.getCurrentUserData();

//       if (currentUserUid == null || currentUserData == null) {
//         print('❌ No user in SessionManager');
//         return;
//       }

//       print(
//           '🔐 Attempting Firebase Auth for SessionManager UID: $currentUserUid');

//       // Use the actual user email from SessionManager data instead of creating a fake one
//       final userEmail = currentUserData['email'];
//       if (userEmail == null || userEmail.isEmpty) {
//         print('❌ No email found in user data, cannot initialize Firebase Auth');
//         _initializeYears(); // Proceed without Firebase Auth
//         return;
//       }

//       // Try to sign in with the actual user email
//       try {
//         print('🔑 Attempting Firebase signIn with actual email: $userEmail');

//         // Try to sign in with the actual email
//         final credential =
//             await FirebaseAuth.instance.signInWithEmailAndPassword(
//           email: userEmail,
//           password: currentUserData['password'] ??
//               currentUserUid, // Use stored password or UID as fallback
//         );
//         print('✅ Firebase signIn successful: ${credential.user?.uid}');
//         _initializeYears();
//       } catch (signInError) {
//         print('❌ SignIn failed: $signInError');
//         print(
//             '❌ Cannot create new Firebase Auth user - user should already exist from login');
//         // Don't create new users here - they should already exist from the login process
//         _initializeYears(); // Proceed without Firebase Auth
//       }
//     } catch (e) {
//       print('❌ Firebase Auth initialization error: $e');
//       _initializeYears();
//     }
//   }

//   Future<void> _initializeYears() async {
//     try {
//       print(
//           '🔍 Initializing available years from salary_records collection...');

//       // Check Firebase Auth status
//       final firebaseUser = FirebaseAuth.instance.currentUser;
//       if (firebaseUser != null) {
//         print('✅ Firebase Auth user: ${firebaseUser.uid}');
//       } else {
//         print('⚠️ No Firebase Auth user - may encounter permission issues');
//       }

//       // Use a simpler approach - test known years directly
//       final currentYear = DateTime.now().year;
//       final testYears = [
//         2025, // From your Firebase screenshot
//         currentYear,
//         currentYear - 1,
//         currentYear - 2,
//         currentYear - 3
//       ];

//       Set<int> validYears = {};

//       for (var year in testYears) {
//         try {
//           print('🔍 Testing year: $year');
//           // Test if the year document exists by trying to access a known month
//           final testDoc = await FirebaseFirestore.instance
//               .collection('salary_records')
//               .doc(year.toString())
//               .collection('April') // Test with April since you have data there
//               .limit(1)
//               .get();

//           if (testDoc.docs.isNotEmpty) {
//             validYears.add(year);
//             print('✅ Found data for year: $year');
//           } else {
//             print('❌ No data found for year: $year');
//           }
//         } catch (e) {
//           print('❌ Error checking year $year: $e');
//         }
//       }

//       if (validYears.isNotEmpty) {
//         availableYears = validYears.toList()
//           ..sort((a, b) => b.compareTo(a)); // Sort descending
//         selectedYear = availableYears.first; // Select most recent year
//         print('✅ Available years: $availableYears, selected: $selectedYear');
//       } else {
//         // Fallback to current year if no records found
//         availableYears = [currentYear];
//         selectedYear = currentYear;
//         print('❌ No valid years found, using current year: $currentYear');
//       }

//       setState(() {});

//       // Fetch salaries after years are initialized
//       _fetchSalaries();
//     } catch (e) {
//       print('❌ Error fetching available years: $e');
//       // Since we have permission issues, use years we know exist (from Firebase screenshot)
//       availableYears = [2025, 2024, 2023, 2022, 2021];
//       selectedYear = 2025; // Use 2025 since we saw data there
//       print('🔄 Using known years from database: $availableYears');
//       setState(() {});
//       _fetchSalaries();
//     }
//   }

//   Future<void> _fetchSalaries() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       // Check Firebase Auth status first
//       final firebaseUser = FirebaseAuth.instance.currentUser;
//       if (firebaseUser != null) {
//         print('✅ Firebase Auth user for salary fetch: ${firebaseUser.uid}');
//       } else {
//         print('⚠️ No Firebase Auth user - will encounter permission issues');
//       }

//       // Use SessionManager for user identification
//       final currentUserUid = await SessionManager.getCurrentUserUid();
//       if (currentUserUid == null) {
//         print('❌ Error: User not authenticated in SessionManager');
//         setState(() {
//           isLoading = false;
//         });
//         return;
//       }

//       print(
//           '🔍 Fetching salaries for user: $currentUserUid, year: $selectedYear');

//       await _fetchYearSalary(
//           selectedYear.toString(), yearlyPayments, currentUserUid);

//       print('✅ Salary fetch completed. Data: $yearlyPayments');
//     } catch (e) {
//       print('❌ Error fetching salaries: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _fetchYearSalary(
//     String year,
//     Map<String, Map<String, dynamic>> paymentsMap,
//     String uid,
//   ) async {
//     paymentsMap.clear();

//     // Try direct document access for known months first
//     final months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December'
//     ];

//     print('Fetching salary data for $year with empId: $uid');

//     for (var month in months) {
//       try {
//         // Try to access the specific document path more directly
//         final monthCollectionRef = FirebaseFirestore.instance
//             .collection('salary_records')
//             .doc(year)
//             .collection(month);

//         print('Querying: salary_records/$year/$month where empId == $uid');

//         // Use get() instead of where() query to avoid permission issues
//         final allDocsSnapshot = await monthCollectionRef.get();

//         print('Found ${allDocsSnapshot.docs.length} documents in $month $year');

//         bool foundUserData = false;

//         for (var doc in allDocsSnapshot.docs) {
//           final data = doc.data();
//           final docEmpId = data['empId']?.toString();

//           print('Document ${doc.id} in $month: empId=$docEmpId');

//           if (docEmpId == uid) {
//             // Parse salary as string from Firebase (as shown in screenshot)
//             final salaryString = data['salary']?.toString() ?? '0';
//             final salaryAmount = int.tryParse(salaryString) ?? 0;

//             // Parse status (as shown in screenshot)
//             final statusString =
//                 data['status']?.toString().toLowerCase() ?? 'unpaid';
//             final isPaid = statusString == 'paid';

//             paymentsMap[month] = {
//               'month': month,
//               'amount': salaryAmount,
//               'status': isPaid,
//             };

//             foundUserData = true;
//             print(
//                 '✅ Found data for $month $year: salary=$salaryAmount, status=$statusString, paid=$isPaid');
//             break;
//           }
//         }

//         if (!foundUserData) {
//           paymentsMap[month] = {
//             'month': month,
//             'amount': 0,
//             'status': false,
//           };
//           print('❌ No matching empId found for $month $year (empId: $uid)');
//         }
//       } catch (e) {
//         print('❌ Error fetching month $month for $year: $e');
//         paymentsMap[month] = {
//           'month': month,
//           'amount': 0,
//           'status': false,
//         };
//       }
//     }

//     print('Completed fetching all months for $year');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SafeArea(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Year Filter Dropdown
//                     Container(
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.blue[200]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.calendar_today, color: Colors.blue[600]),
//                           SizedBox(width: 12),
//                           Text(
//                             'Select Year: ',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.blue[800],
//                             ),
//                           ),
//                           Expanded(
//                             child: DropdownButtonHideUnderline(
//                               child: availableYears.isEmpty
//                                   ? Text(
//                                       'Loading years...',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontStyle: FontStyle.italic,
//                                         color: Colors.grey[600],
//                                       ),
//                                     )
//                                   : DropdownButton<int>(
//                                       value:
//                                           availableYears.contains(selectedYear)
//                                               ? selectedYear
//                                               : availableYears.first,
//                                       isExpanded: true,
//                                       items: availableYears.map((year) {
//                                         return DropdownMenuItem<int>(
//                                           value: year,
//                                           child: Text(
//                                             year.toString(),
//                                             style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                         );
//                                       }).toList(),
//                                       onChanged: (newYear) {
//                                         if (newYear != null) {
//                                           setState(() {
//                                             selectedYear = newYear;
//                                           });
//                                           _fetchSalaries();
//                                         }
//                                       },
//                                     ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(height: 20),

//                     // Monthly Salary Grid
//                     Text(
//                       'Monthly Salary Records - $selectedYear',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     SizedBox(height: 16),

//                     // Calculate total yearly salary
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.green[400]!, Colors.green[600]!],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Total Yearly Salary',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           Text(
//                             '₹${_calculateTotalSalary()}',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(height: 16),

//                     // Monthly Grid
//                     GridView.builder(
//                       shrinkWrap: true,
//                       physics: NeverScrollableScrollPhysics(),
//                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         childAspectRatio: 1.2,
//                         crossAxisSpacing: 12,
//                         mainAxisSpacing: 12,
//                       ),
//                       itemCount: 12,
//                       itemBuilder: (context, index) {
//                         final months = [
//                           'January',
//                           'February',
//                           'March',
//                           'April',
//                           'May',
//                           'June',
//                           'July',
//                           'August',
//                           'September',
//                           'October',
//                           'November',
//                           'December'
//                         ];
//                         final month = months[index];
//                         final monthData = yearlyPayments[month] ??
//                             {
//                               'month': month,
//                               'amount': 0,
//                               'status': false,
//                             };

//                         return _buildMonthCard(
//                           month: monthData['month'],
//                           amount: monthData['amount'],
//                           isPaid: monthData['status'],
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   int _calculateTotalSalary() {
//     int total = 0;
//     yearlyPayments.forEach((month, data) {
//       if (data['status'] == true) {
//         total += (data['amount'] as int);
//       }
//     });
//     return total;
//   }

//   Widget _buildMonthCard({
//     required String month,
//     required int amount,
//     required bool isPaid,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isPaid
//               ? [Colors.green[100]!, Colors.green[200]!]
//               : [Colors.red[100]!, Colors.red[200]!],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: isPaid ? Colors.green[300]! : Colors.red[300]!,
//           width: 1,
//         ),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(8),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Flexible(
//               child: Text(
//                 month.substring(0, 3), // Show short month name
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: isPaid ? Colors.green[800] : Colors.red[800],
//                 ),
//                 overflow: TextOverflow.ellipsis,
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             SizedBox(height: 4),
//             Flexible(
//               child: Text(
//                 '₹${amount.toString()}',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: isPaid ? Colors.green[900] : Colors.red[900],
//                 ),
//                 overflow: TextOverflow.ellipsis,
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             SizedBox(height: 4),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: isPaid ? Colors.green[600] : Colors.red[600],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 isPaid ? 'Paid' : 'Unpaid',
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.white,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class ProfilePage extends StatefulWidget {
  final bool showAppBar;

  const ProfilePage({super.key, this.showAppBar = true});

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes visible
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print("Fetching user data for profile page...");

      // Use SessionManager to get cached user data
      Map<String, dynamic>? data = await SessionManager.getCurrentUserData();

      if (data != null) {
        setState(() {
          userData = data;
          _profileImageUrl = userData!["profileImageUrl"];

          // Check for the new 'profilephoto' field first, then fallback to old field
          _profilePicBinary =
              userData!["profilephoto"] ?? userData!["profilePicBinary"];

          // 🔹 Print values for debugging
          print("Profile Image URL: $_profileImageUrl");
          print(
              "Profile Binary String: ${_profilePicBinary?.substring(0, 50) ?? 'null'}...");

          if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
            try {
              _profileImageBytes = base64Decode(_profilePicBinary!);
              print("Decoded image bytes: ${_profileImageBytes!.length} bytes");
            } catch (e) {
              print("Error decoding base64: $e");
            }
          } else {
            print("No profile image found in Firestore");
          }

          _isLoading = false;
        });
      } else {
        print("No user data found, trying fallback method...");
        await _fetchUserDataFallback();
      }
    } catch (e) {
      print("Error fetching user data: $e");
      await _fetchUserDataFallback();
    }
  }

  Future<void> _fetchUserDataFallback() async {
    try {
      // Fallback: Get current Firebase Auth user
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        print("No Firebase Auth user found");
        // Try to get from SessionManager as fallback
        String? sessionUid = await SessionManager.getCurrentUserUid();
        if (sessionUid != null) {
          await _fetchUserDataByCustomUid(sessionUid);
          return;
        }
        print("No user authentication found");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("Firebase Auth UID: ${firebaseUser.uid}");

      // Look up customUid in uid_mapping collection
      DocumentSnapshot mappingDoc = await FirebaseFirestore.instance
          .collection("uid_mapping")
          .doc(firebaseUser.uid)
          .get();

      if (!mappingDoc.exists) {
        print("No mapping found for Firebase UID: ${firebaseUser.uid}");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> mappingData =
          mappingDoc.data() as Map<String, dynamic>;
      String customUid = mappingData['customUid'];
      print("Found custom UID: $customUid");

      // Fetch user data using customUid
      await _fetchUserDataByCustomUid(customUid);
    } catch (e) {
      print("Error in fallback user data fetch: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserDataByCustomUid(String customUid) async {
    try {
      print("Fetching user data for custom UID: $customUid");

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(customUid)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
          _profileImageUrl = userData!["profileImageUrl"];
          _profilePicBinary = userData!["profilePicBinary"];

          // 🔹 Print values for debugging
          print("Profile Image URL: $_profileImageUrl");
          print(
              "Profile Binary String: ${_profilePicBinary?.substring(0, 50) ?? 'null'}...");

          if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
            try {
              _profileImageBytes = base64Decode(_profilePicBinary!);
              print("Decoded image bytes: ${_profileImageBytes!.length} bytes");
            } catch (e) {
              print("Error decoding base64: $e");
            }
          } else {
            print("No profile image found in Firestore");
          }

          _isLoading = false;
        });
      } else {
        print("User document does not exist for custom UID: $customUid");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data by custom UID: $e");
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

    try {
      // Step 1: Check Firebase Auth and try to refresh if needed
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        print(
            "No Firebase user authenticated - trying to establish Firebase auth");

        // Try to sign in anonymously to establish Firebase authentication
        try {
          UserCredential userCredential =
              await FirebaseAuth.instance.signInAnonymously();
          firebaseUser = userCredential.user;
          print("✅ Established anonymous Firebase auth: ${firebaseUser?.uid}");
        } catch (authError) {
          print("⚠️ Failed to establish Firebase auth: $authError");
          // Continue without Firebase auth - Firestore rules now allow this
        }

        // Try to get user data from SessionManager as fallback
        String? sessionUid = await SessionManager.getCurrentUserUid();
        Map<String, dynamic>? sessionData =
            await SessionManager.getCurrentUserData();

        if (sessionUid != null && sessionData != null) {
          print("Found session data - proceeding with upload");
          print("Session UID: $sessionUid");
          print("Session EID: ${sessionData['Eid']}");

          // Use session data directly
          String documentId = sessionUid;
          String? currentUserEid = sessionData['Eid'];

          // Step 2: Read and process image
          Uint8List originalBytes = await file.readAsBytes();
          img.Image? image = img.decodeImage(originalBytes);

          if (image == null) {
            throw Exception("Failed to decode image");
          }

          // Step 3: Compress Image
          Uint8List compressedBytes =
              Uint8List.fromList(img.encodeJpg(image, quality: 50));

          // Step 4: Convert to Base64 for Firestore Storage
          String base64String = base64Encode(compressedBytes);

          // Step 5: Try multiple document update approaches
          bool updateSuccess = false;

          // Approach 1: Try using session UID
          try {
            print("Attempting update with session UID: $sessionUid");
            await FirebaseFirestore.instance
                .collection("users")
                .doc(sessionUid)
                .update({
              "profilephoto": base64String,
              "profileImageUrl": null,
            });
            updateSuccess = true;
            documentId = sessionUid;
            print(
                "✅ Successfully updated profile using session UID: $sessionUid");
          } catch (e) {
            print("❌ Failed to update using session UID: $e");

            // Approach 2: Try using EID if session UID failed
            if (currentUserEid != null && currentUserEid.isNotEmpty) {
              try {
                print("Attempting update with EID: $currentUserEid");
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(currentUserEid)
                    .update({
                  "profilephoto": base64String,
                  "profileImageUrl": null,
                });
                updateSuccess = true;
                documentId = currentUserEid;
                print(
                    "✅ Successfully updated profile using EID: $currentUserEid");
              } catch (eidError) {
                print("❌ Failed to update using EID: $eidError");
              }
            }
          }

          if (!updateSuccess) {
            throw Exception(
                "Could not update profile in Firestore with session UID ($sessionUid) or EID ($currentUserEid)");
          }

          // Update local state
          setState(() {
            _profilePicBinary = base64String;
            _profileImageBytes = compressedBytes;
            _profileImageUrl = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile picture updated successfully!")),
          );

          print(
              "✅ Profile picture update completed successfully using session data");
          return;
        }

        // If no session data either, show error
        print("No authentication available - neither Firebase nor session");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Authentication required. Please log in again.")),
        );
        return;
      }

      String firebaseUid = firebaseUser.uid;
      print("Uploading profile picture for Firebase UID: $firebaseUid");

      // Get current user's EID from SessionManager
      Map<String, dynamic>? currentUserData =
          await SessionManager.getCurrentUserData();
      String? currentUserEid = currentUserData?['Eid'];

      print("Current user EID: $currentUserEid");

      // Step 2: Read Image as Bytes
      Uint8List originalBytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(originalBytes);

      if (image == null) {
        throw Exception("Failed to decode image");
      }

      // Step 3: Compress Image
      Uint8List compressedBytes =
          Uint8List.fromList(img.encodeJpg(image, quality: 50));

      // Step 4: Convert to Base64 for Firestore Storage
      String base64String = base64Encode(compressedBytes);

      // Step 5: Try to update using Firebase UID first (most likely document structure)
      bool updateSuccess = false;
      String documentId = firebaseUid;

      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(firebaseUid)
            .update({
          "profilephoto": base64String, // Use 'profilephoto' as requested
          "profileImageUrl": null, // Clear any existing URL-based field
        });
        updateSuccess = true;
        print("Successfully updated profile using Firebase UID: $firebaseUid");
      } catch (e) {
        print("Failed to update using Firebase UID: $e");

        // Fallback: Try using EID if Firebase UID failed
        if (currentUserEid != null && currentUserEid.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection("users")
                .doc(currentUserEid)
                .update({
              "profilephoto": base64String,
              "profileImageUrl": null,
            });
            updateSuccess = true;
            documentId = currentUserEid;
            print("Successfully updated profile using EID: $currentUserEid");
          } catch (eidError) {
            print("Failed to update using EID: $eidError");
          }
        }
      }

      if (!updateSuccess) {
        throw Exception(
            "Could not update profile in Firestore with either UID or EID");
      }

      // Step 6: Update Firebase Storage (optional - keeping for backward compatibility)
      try {
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child("profile_pictures/$documentId.jpg");
        await storageRef.putData(compressedBytes);
        String imageUrl = await storageRef.getDownloadURL();

        // Update Firestore with storage URL as backup
        await FirebaseFirestore.instance
            .collection("users")
            .doc(documentId)
            .update({"profileImageUrl": imageUrl});

        print("Also saved to Firebase Storage: $imageUrl");
      } catch (storageError) {
        print("Storage upload failed (non-critical): $storageError");
        // Don't fail the whole operation if storage fails
      }

      // Step 7: Update local state
      setState(() {
        _profilePicBinary = base64String;
        _profileImageBytes = compressedBytes;
        // Clear URL-based image since we're now using binary
        _profileImageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile picture updated successfully!")),
      );

      print("Profile picture update completed successfully");
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading profile picture: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent = _isLoading
        ? Center(child: CircularProgressIndicator())
        : userData == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "No profile data found",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: Icon(Icons.logout),
                      label: Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
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
                      _buildInfoRow("Alternate Mobile", userData!["altMobile"]),
                      _buildInfoRow(
                          "Emergency Contact", userData!["emergencyContact"]),
                      _buildInfoRow("Blood Group", userData!["bloodGroup"]),
                      _buildInfoRow("Gender", userData!["gender"]),
                      _buildInfoRow("Father Name", userData!["fatherName"]),
                      _buildInfoRow("Father Mobile", userData!["fatherMobile"]),
                      _buildInfoRow("Mother Name", userData!["motherName"]),
                      _buildInfoRow("Mother Mobile", userData!["motherMobile"]),
                      _buildInfoRow("Spouse Name", userData!["spouseName"]),
                      _buildInfoRow("Spouse Mobile", userData!["spouseMobile"]),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Log Out",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ],
                ),
              );

    // If showAppBar is false, just return the body content (for use in bottom nav)
    if (!widget.showAppBar) {
      return bodyContent;
    }

    // Otherwise, wrap in Scaffold with AppBar (for standalone navigation)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 70,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(30),
          ),
        ),
        actions: [
          // Always visible logout button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: bodyContent,
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
    // Show confirmation dialog
    bool shouldLogout = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text(
                    'Logging out...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Clear SessionManager data
      await SessionManager.clearUserSession();
      print('SessionManager logout completed');

      // Sign out from Firebase Auth
      try {
        await FirebaseAuth.instance.signOut();
        print('Firebase Auth logout completed');
      } catch (firebaseError) {
        print('Firebase logout error (continuing anyway): $firebaseError');
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to login page and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false, // This will remove all routes from the stack
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully logged out'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.of(context).pop();

      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
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
