import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data'; // Fix: Import Uint8List
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

/// The main widget that fetches all users with status == false and displays them.
class RejectedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rejected",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where("status", isEqualTo: "temporary delete")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No users pending approval",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final userData = doc.data() as Map<String, dynamic>;
              return UserCard(userData: userData, docId: doc.id);
            },
          );
        },
      ),
    );
  }
}

class UserCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String docId;

  const UserCard({Key? key, required this.userData, required this.docId})
      : super(key: key);

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller for expand/collapse.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded)
        _controller.forward();
      else
        _controller.reverse();
    });
  }

  /// **Update user status (Approve)**
  Future<void> _updateStatus(bool approved) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.docId)
          .update({'status': approved});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? "User approved" : "User denied")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: $e")),
      );
    }
  }

  /// **Delete user permanently with confirmation dialog & authentication deletion**
  Future<void> _confirmDelete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text(
          "Are you sure you want to permanently delete this employee?\n\n"
          "This will also remove their authentication access. Once deleted, you cannot retrieve this data.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              deleteUserFromAuth();
              Navigator.pop(context, true);
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        String? email = widget.userData['email'];
        if (email != null && email.isNotEmpty) {
          List<String> signInMethods =
              await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

          if (signInMethods.isNotEmpty) {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await user.delete();
            }
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "User deleted permanently from Firestore and Firebase Authentication")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting user: $e")),
        );
      }
    }
  }

  Future<void> deleteUserFromAuth() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.delete();
        print("User deleted from Firebase Authentication.");
      }
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  Widget _buildDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$label: ${value ?? "Not available"}',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var user = widget.userData;

    // Decode base64 image data
    Uint8List? _decodeImage(String? base64String) {
      if (base64String == null || base64String.isEmpty) return null;
      try {
        return base64Decode(base64String);
      } catch (e) {
        print("Error decoding image: $e");
        return null;
      }
    }

    // Decode profile image from binary
    Uint8List? profileImageBytes = _decodeImage(user['profilePicBinary']);

    Uint8List? frontAadharImage =
        _decodeImage(user['front_aadhar_image_bitcode']);
    Uint8List? backAadharImage =
        _decodeImage(user['back_aadhar_image_bitcode']);
    Uint8List? signatureImage = _decodeImage(user['signature_image_bitcode']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Avatar, name, and expand/collapse button.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blueAccent,
                      backgroundImage: profileImageBytes != null
                          ? MemoryImage(profileImageBytes)
                          : null,
                      child: profileImageBytes == null
                          ? Icon(Icons.person, size: 30, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      user['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _toggleExpanded,
                  child: Text(
                    _isExpanded ? 'Hide' : 'Show More',
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
            // Expandable details section with smooth animation.
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildDetail('Name', user['name']),
                  _buildDetail('Qualification', user['qualification']),
                  _buildDetail('Experience', user['experience']),
                  _buildDetail('DOB', user['dob']),
                  _buildDetail('Age', user['age']),
                  _buildDetail('Gender', user['gender']),
                  _buildDetail('Address', user['address']),
                  _buildDetail('District', user['district']),
                  _buildDetail('State', user['state']),
                  _buildDetail('Pincode', user['pincode']),
                  _buildDetail('Mobile', user['mobile']),
                  _buildDetail('Emergency Contact', user['emergencyContact']),
                  _buildDetail('Email', user['email']),
                  _buildDetail('Alternative Number', user['altMobile']),
                  _buildDetail('Whatsapp Number', user['whatsapp']),
                  _buildDetail('Native', user['native']),
                  _buildDetail('Religion', user['religion']),
                  _buildDetail('Cast', user['cast']),
                  _buildDetail('Blood Group', user['bloodGroup']),
                  _buildDetail('Father Name', user['fatherName']),
                  _buildDetail('Father Mobile', user['fatherMobile']),
                  _buildDetail('Mother Name', user['motherName']),
                  _buildDetail('Mother Mobile', user['motherMobile']),
                  _buildDetail('Spouse Name', user['spouseName']),
                  _buildDetail('Spouse Mobile', user['spouseMobile']),
                  _buildDetail('Aadhar Number', user['aadhar']),
                  _buildDetail('Pan Number', user['pan']),
                  _buildDetail('Epf Number', user['epf']),
                  _buildDetail('Esi Number', user['esi']),
                  _buildDetail('Bank Name', user['bank_name']),
                  _buildDetail('Account Holder', user['account_holder']),
                  _buildDetail('Account Number', user['account_number']),
                  _buildDetail('IFSC Number', user['ifsc']),
                  _buildDetail('Emergency Contact', user['emergencyContact']),
                  // Display Decoded Aadhar Front Image
                  if (frontAadharImage != null) ...[
                    const SizedBox(height: 12),
                    const Text("Front Aadhar Image",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullScreenImage(imageBytes: frontAadharImage),
                          ),
                        );
                      },
                      child: Hero(
                        tag:
                            "aadhaarFront_${widget.docId}", // Unique tag for smooth animation
                        child: Image.memory(
                          frontAadharImage,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],

                  // Display Decoded Aadhaar Back Image
                  if (backAadharImage != null) ...[
                    const SizedBox(height: 12),
                    const Text("Back Aadhar Image",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullScreenImage(imageBytes: backAadharImage),
                          ),
                        );
                      },
                      child: Hero(
                        tag:
                            "aadhaarBack_${widget.docId}", // Unique tag for smooth animation
                        child: Image.memory(
                          backAadharImage,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],

                  // Display Signature Image
                  if (signatureImage != null) ...[
                    const SizedBox(height: 12),
                    const Text("Signature",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullScreenImage(imageBytes: signatureImage),
                          ),
                        );
                      },
                      child: Hero(
                        tag:
                            "SignatureImage_${widget.docId}", // Unique tag for smooth animation
                        child: Image.memory(
                          signatureImage,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  /// **Approval & Delete Buttons**
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /// ✅ **Approve Button (Changes Status to `true`)**
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _updateStatus(true),
                        child: const Text(
                          "Approve",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// ❌ **Permanently Delete Button with Confirmation Dialog**
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _confirmDelete,
                        child: const Text(
                          "Permanently Delete",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
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
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final Uint8List imageBytes;

  const FullScreenImage({Key? key, required this.imageBytes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Full Screen Image"),
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: Hero(
          tag: "aadhaarFront",
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
