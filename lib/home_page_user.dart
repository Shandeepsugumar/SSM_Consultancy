import 'dart:convert';
import 'dart:io';
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
          icon: const Icon(Icons.arrow_back, color: Colors.white,),
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
    fetchUserName(); // Fetch user name when screen loads
  }

  Future<void> fetchUserName() async {
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
        print("Profile Binary String: ${_profilePicBinary?.substring(0, 50)}..."); // Print first 50 characters

        if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
          try {
            _profileImageBytes = base64Decode(_profilePicBinary!);
            print("Decoded image bytes: ${_profileImageBytes!.length} bytes");  // ✅ Confirm image bytes exist
          } catch (e) {
            print("Error decoding base64: $e");  // 🚨 Catch decoding errors
          }
        } else {
          print("No profile image found in Firestore"); // 🚨 If no binary data exists
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _isLoading
              ? CircularProgressIndicator()
              : _buildProfileSection(),
          SizedBox(height: 16),
          _buildQuickAccessSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.black26,
            backgroundImage: _profileImageBytes != null
                ? MemoryImage(_profileImageBytes!)  // ✅ Load from Firestore Binary
                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                ? NetworkImage(_profileImageUrl!)  // ✅ Load from Firebase Storage
                : null),
            child: (_profileImageUrl == null && _profileImageBytes == null)
                ? Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              userData != null ? userData!["name"] ?? "Unknown" : "Unknown",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
      IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          onPressed: () => ProfilePage,
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Access",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            children: [
              _buildQuickAccessItem(Icons.calendar_today, "My Schedule"),
              _buildQuickAccessItem(Icons.assignment, "My Attendance"),
              _buildQuickAccessItem(Icons.account_balance, "My Accounts"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
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
                _buildShiftCard(
                    "Morning Shift", "Open spots available", 4, Colors.orange, []),
                _buildShiftCard("Afternoon Shift", "5/5 shift tasks completed", 5,
                    Colors.yellow, ["avatar1"]),
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
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
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
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
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
          .map((day) => Text(day, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    int startWeekday = _firstDayOfMonth.weekday % 7; // Adjust to start from Sunday
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
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, day);
            });
          },
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isToday ? Colors.blue : (_selectedDate.day == day ? Colors.grey[300] : null),
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


  Widget _buildShiftCard(
      String title, String subtitle, int progress, Color color, List<String> avatars) {
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
                Text(title, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                if (avatars.isNotEmpty)
                  Row(
                    children: avatars
                        .map((e) =>
                        CircleAvatar(backgroundColor: Colors.white, radius: 14))
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

        if (!isTiming) {
          startTime = DateTime.now();
          elapsedTime = Duration(seconds: 0);
          _startTimer();
        } else {
          _stopTimer();
        }

        setState(() {
          isTiming = !isTiming;
        });

        _saveTimerState(); // Save state persistently
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Authentication Failed!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Fingerprint scanner not available."),
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
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
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
        print("Profile Binary String: ${_profilePicBinary?.substring(0, 50)}..."); // Print first 50 characters

        if (_profilePicBinary != null && _profilePicBinary!.isNotEmpty) {
          try {
            _profileImageBytes = base64Decode(_profilePicBinary!);
            print("Decoded image bytes: ${_profileImageBytes!.length} bytes");  // ✅ Confirm image bytes exist
          } catch (e) {
            print("Error decoding base64: $e");  // 🚨 Catch decoding errors
          }
        } else {
          print("No profile image found in Firestore"); // 🚨 If no binary data exists
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
      Uint8List compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 50));

      // 🔹 Step 3: Convert to Base64 for Firestore Storage
      String base64String = base64Encode(compressedBytes);

      // 🔹 Step 4: Upload Binary to Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({"profilePicBinary": base64String});

      // 🔹 Step 5: Upload Image to Firebase Storage
      Reference storageRef =
      FirebaseStorage.instance.ref().child("profile_pictures/${user.uid}.jpg");
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
          child: Text("No profile data found",
              style: TextStyle(color: Colors.black)))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.black26,
                  backgroundImage: _profileImageBytes != null
                      ? MemoryImage(_profileImageBytes!)  // ✅ Load from Firestore Binary
                      : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!)  // ✅ Load from Firebase Storage
                      : null),
                  child: (_profileImageUrl == null && _profileImageBytes == null)
                      ? Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _uploadProfilePicture,
                    child: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 20,
                      child: Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 10),
            Text(
              userData!["name"] ?? "Unknown",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              userData!["email"] ?? "",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            _buildInfoSection("Personal Info",[
              _buildInfoRow("Qualification", userData!["qualification"]),
              _buildInfoRow("Experience", userData!["experience"]),
              _buildInfoRow("Age", userData!["age"]),
              _buildInfoRow("Date Of Birth", userData!["dob"]),
              _buildInfoRow("Whatsapp Number", userData!["whatsapp"]),
              _buildInfoRow("Mobile", userData!["mobile"]),
              _buildInfoRow("Alternate Mobile", userData!["altMobile"]),
              _buildInfoRow("Emergency Contact", userData!["emergencyContact"]),
              _buildInfoRow("Blood Group", userData!["bloodGroup"]),
              _buildInfoRow("Gender", userData!["gender"]),
              _buildInfoRow("Father Name", userData!["fatherName"]),
              _buildInfoRow("Father Mobile", userData!["fatherMobile"]),
              _buildInfoRow("Mother Name", userData!["motherName"]),
              _buildInfoRow("Mother Mobile", userData!["motherMobile"]),
              _buildInfoRow("Spouse Name", userData!["spouseName"]),
              _buildInfoRow("Spouse Mobile", userData!["spouseMobile"]),
            ]),
            _buildInfoSection("Address Details", [
              _buildInfoRow("Address", userData!["address"]),
              _buildInfoRow("District", userData!["district"]),
              _buildInfoRow("State", userData!["state"]),
              _buildInfoRow("Pincode", userData!["pincode"]),
              _buildInfoRow("Native Place", userData!["native"]),
            ]),
            _buildInfoSection("Bank Details", [
              _buildInfoRow("Bank Name", userData!["bank_name"]),
              _buildInfoRow("Account Number", userData!["account_number"]),
              _buildInfoRow("Account Holder Name", userData!["account_holder"]),
              _buildInfoRow("IFSC Code", userData!["ifsc"]),
            ]),
            _buildInfoSection("Additional info", [
              _buildInfoRow("Aadhar Number", userData!["aadhar"]),
              _buildInfoRow("EPF Number", userData!["epf"]),
              _buildInfoRow("ESI Number", userData!["esi"]),
              _buildInfoRow("IFSC Number", userData!["ifsc"]),
              _buildInfoRow("PAN Number", userData!["pan"]),
              _buildInfoRow("Religion", userData!["religion"]),
              _buildInfoRow("Cast", userData!["cast"]),
            ]),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Log Out", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.black),
                onPressed: () {},
              )
            ],
          ),
          Divider(color: Colors.black),
          ...children
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            value ?? "Not provided",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
