import 'dart:convert';
import 'dart:io';
import 'package:consultancy/loginpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    ScheduleScreen(),
    AttendanceScreen(),
    AccountsScreen(),
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
        backgroundColor: Colors.blue[900],
        toolbarHeight: 70, // Increase the height of the AppBar
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
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
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
            MaterialPageRoute(builder: (context) => ScheduleScreen()),
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

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _currentDate = DateTime.now();
  late int _daysInMonth;
  late DateTime _firstDayOfMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _currentDate;
    _updateCalendar();
  }

  void _updateCalendar() {
    _firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    _updateCalendar();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildMonthSelector(),
          SizedBox(height: 10),
          _buildWeekDays(),
          _buildCalendarGrid(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(12.0),
              children: [
                _buildShiftCard("Morning Shift", "Open spots available", 4,
                    Colors.orange, []),
                _buildShiftCard("Afternoon Shift", "5/5 shift tasks completed",
                    5, Colors.yellow, ["avatar1"]),
                _buildShiftCard("Evening Shift", "3/5 shift tasks completed", 3,
                    Colors.pink, ["avatar2", "avatar3"]),
                _buildShiftCard("Evening Shift", "1/5 shift tasks completed", 1,
                    Colors.purple, ["avatar4", "avatar5"]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_left, size: 30),
          onPressed: () {
            setState(() {
              _selectedDate =
                  DateTime(_selectedDate.year, _selectedDate.month - 1);
              _updateCalendar();
            });
          },
        ),
        Text(
          DateFormat('MMMM yyyy').format(_selectedDate),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.arrow_right, size: 30),
          onPressed: () {
            setState(() {
              _selectedDate =
                  DateTime(_selectedDate.year, _selectedDate.month + 1);
              _updateCalendar();
            });
          },
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    List<String> weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekDays
          .map((day) => Text(day,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    int startWeekday =
        _firstDayOfMonth.weekday % 7; // Adjust to start from Sunday
    int totalSlots = _daysInMonth + startWeekday;
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < startWeekday) {
          return Container(); // Empty cell
        }

        int day = index - startWeekday + 1;
        bool isToday = (day == _currentDate.day &&
            _selectedDate.month == _currentDate.month &&
            _selectedDate.year == _currentDate.year);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate =
                  DateTime(_selectedDate.year, _selectedDate.month, day);
            });
          },
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.blue
                  : (_selectedDate.day == day ? Colors.grey[300] : null),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              "$day",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShiftCard(String title, String subtitle, int progress,
      Color color, List<String> avatars) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.2),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (avatars.isNotEmpty)
                  Row(
                    children: avatars
                        .map((e) => CircleAvatar(
                            backgroundColor: Colors.white, radius: 14))
                        .toList(),
                  ),
              ],
            ),
            SizedBox(height: 5),
            LinearProgressIndicator(value: progress / 5, color: color),
            SizedBox(height: 5),
            Text(subtitle, style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _loadTimerState(); // Load the previous timer state if exists
  }

  /// Load previous timer state
  Future<void> _loadTimerState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool wasTiming = prefs.getBool('isTiming') ?? false;
    String? savedStartTime = prefs.getString('startTime');

    if (wasTiming && savedStartTime != null) {
      startTime = DateTime.parse(savedStartTime);
      isTiming = true;
      _startTimer();
    }

    setState(() {});
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
  }

  /// Fingerprint Authentication & Timer Control
  Future<void> _scanFingerprint() async {
    bool isAuthenticated = false;

    try {
      isAuthenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to mark attendance',
        options: AuthenticationOptions(biometricOnly: true),
      );

      if (isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Attendance Marked Successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        final FirebaseFirestore _firestore = FirebaseFirestore.instance;
        final User? user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          print("User is not logged in");
          return;
        }

        final String userUid = user.uid; // Get the UID of the current user
        final DateTime now = DateTime.now();
        final String currentDate = DateFormat('yyyy-MM-dd').format(now);

        // Fetch the user's name from the users collection
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userUid).get();
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        String? userName = userData?['name'];

        if (userName == null) {
          print("User name not found in Firestore");
          return;
        }

        if (!isTiming) {
          // Clocking In
          startTime = now;
          checkInTime = startTime;
          elapsedTime = Duration(seconds: 0);
          _startTimer();
        } else {
          // Clocking Out
          checkOutTime = now;
          _stopTimer();
        }

        // Calculate hours, minutes, and seconds
        int hours = elapsedTime.inHours;
        int minutes = elapsedTime.inMinutes % 60;
        int seconds = elapsedTime.inSeconds % 60;

        // Log the user name and Firestore write operation
        print("User Name: $userName");
        print("Writing to Firestore...");

        // Save to Firestore under user's UID collection with document named after the date
        await _firestore
            .collection('attendance')
            .doc(userUid)
            .collection('dates')
            .doc(currentDate)
            .set({
          'name': userName, // Store the user's name
          'checkInTime': checkInTime?.toIso8601String(),
          'checkOutTime': checkOutTime?.toIso8601String(),
          'elapsedTime': '$hours"hrs":$minutes"mins":$seconds"secs"',
          'currentDate': currentDate,
        }, SetOptions(merge: true));

        print("Write successful");

        setState(() {
          isTiming = !isTiming;
        });

        _saveTimerState();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Authentication Failed!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Start Timer
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        elapsedTime = DateTime.now().difference(startTime!);
      });
    });
  }

  /// Stop Timer
  void _stopTimer() {
    _timer?.cancel();
    _saveTimerState(); // Save final state
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
                  onPressed: _scanFingerprint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: CircleBorder(),
                    elevation: 20,
                    padding: EdgeInsets.all(0),
                  ),
                  child: Icon(Icons.fingerprint, size: 60, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),

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
                Text(
                  "Check-in: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(checkInTime!)}",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              if (checkOutTime != null)
                Text(
                  "Check-out: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(checkOutTime!)}",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Accounts Page"));
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
