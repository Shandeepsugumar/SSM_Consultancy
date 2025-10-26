import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data'; // Fix: Import Uint8List
import 'dart:convert';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

/// The main widget that fetches all users with status == false and displays them.
class ApprovedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Approved",
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
            .where("status", isEqualTo: true)
            .where("status",
            isNotEqualTo:
            "temporary delete") // Exclude "temporary delete" users
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
  String? _profileImageUrl;
  String? _profilePicBinary;
  Uint8List? _profileImageBytes;
  Map<String, dynamic>? userData;

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

  Future<void> _updateStatus(bool approved) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.docId)
          .get();

      if (doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.docId)
            .update({'status': approved ? true : "temporary delete"});

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
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(approved ? "User approved" : "User denied")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating status: $e")),
        );
      }
    }
  }

  Future<void> generateEmployeePDF(Map<String, dynamic> user) async {
    final pdf = pw.Document();

    // Decode images
    Uint8List? profileImageBytes = _decodeImage(user['profilePicBinary']);
    Uint8List? frontAadharBytes = _decodeImage(user['front_aadhar_image_bitcode']);
    Uint8List? backAadharBytes = _decodeImage(user['back_aadhar_image_bitcode']);
    Uint8List? signatureBytes = _decodeImage(user['signature_image_bitcode']);

    final profileImage = profileImageBytes != null ? pw.MemoryImage(profileImageBytes) : null;
    final frontAadharImage = frontAadharBytes != null ? pw.MemoryImage(frontAadharBytes) : null;
    final backAadharImage = backAadharBytes != null ? pw.MemoryImage(backAadharBytes) : null;
    final signatureImage = signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;

    int formNumber = await _getFormNumber();
    DateTime date = (user['timestamp'] as Timestamp).toDate();

    // First Page - Text Details
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'SRI SAKTHIMURUGHAN ENTERPRISES\nSSM MANPOWER CONTRACTOR',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Form Number: $formNumber'),
                      pw.SizedBox(height: 2),
                      pw.Text('Date: ${date.toLocal().toString().split(' ')[0]}'),
                    ],
                  ),
                  if (profileImage != null)
                    pw.Container(width: 80, height: 80, child: pw.Image(profileImage)),
                ],
              ),
              pw.SizedBox(height: 10),
              _buildpdfDetail('Name of Employee', user['name']),
              _buildpdfDetail('Education Qualification', user['qualification']),
              _buildpdfDetail('Experience', user['experience']),
              _buildpdfDetail('Date of Birth', user['dob']),
              _buildpdfDetail('Age', user['age']),
              _buildpdfDetail('Gender', user['gender']),
              _buildpdfDetail('Permanent Address', user['address']),
              _buildpdfDetail('District', user['district']),
              _buildpdfDetail('State', user['state']),
              _buildpdfDetail('Pincode', user['pincode']),
              _buildpdfDetail('Mobile Number', user['mobile']),
              _buildpdfDetail('Alternative Mobile Number', user['altMobile']),
              _buildpdfDetail('WhatsApp Number', user['whatsapp']),
              _buildpdfDetail('Native', user['native']),
              _buildpdfDetail('Religion', user['religion']),
              _buildpdfDetail('Cast', user['cast']),
              _buildpdfDetail('Emergency Contact No', user['emergencyContact']),
              _buildpdfDetail('Blood Group', user['bloodGroup']),
              _buildpdfDetail('Email ID', user['email']),
              _buildpdfDetail('Father Name', user['fatherName']),
              _buildpdfDetail('Father Mobile', user['fatherMobile']),
              _buildpdfDetail('Mother Name', user['motherName']),
              _buildpdfDetail('Mother Mobile', user['motherMobile']),
              _buildpdfDetail('Spouse Name', user['spouseName']),
              _buildpdfDetail('Spouse Mobile', user['spouseMobile']),
              _buildpdfDetail('Aadhar Number', user['aadhar']),
              _buildpdfDetail('Pan Number', user['pan']),
              _buildpdfDetail('EPF Number', user['epf']),
              _buildpdfDetail('ESI Number', user['esi']),
              _buildpdfDetail('Bank Name', user['bank_name']),
              _buildpdfDetail('Account Holder', user['account_holder']),
              _buildpdfDetail('Account Number', user['account_number']),
              _buildpdfDetail('IFSC Code', user['ifsc']),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Signature of INCHARGE', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('Signature of SUPERVISOR/MANAGER', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('Signature of MANAGING DIRECTOR', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Profile Image Page (if exists)
    if (profileImage != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Profile Photo',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: 400,
                    height: 500,
                    child: pw.Image(profileImage, fit: pw.BoxFit.contain),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Front Aadhar Page (if exists)
    if (frontAadharImage != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Front Aadhar Card',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: 400,
                    height: 500,
                    child: pw.Image(frontAadharImage, fit: pw.BoxFit.contain),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Back Aadhar Page (if exists)
    if (backAadharImage != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Back Aadhar Card',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: 400,
                    height: 500,
                    child: pw.Image(backAadharImage, fit: pw.BoxFit.contain),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Signature Page (if exists)
    if (signatureImage != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Signature',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: 400,
                    height: 200,
                    child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Save or download the PDF
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/employee_form_${user['name']}.pdf");
    await file.writeAsBytes(await pdf.save());

    final filePath = file.path;
    print("PDF Saved: $filePath");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF saved at $filePath"),
          action: SnackBarAction(
            label: "Open",
            onPressed: () => OpenFile.open(filePath),
          ),
        ),
      );
    }
  }

  pw.Widget _buildpdfDetail(String title, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text('$title: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value ?? 'N/A'),
        ],
      ),
    );
  }

  Uint8List? _decodeImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding image: $e");
      return null;
    }
  }

  Future<int> _getFormNumber() async {
    // Fetch the total number of users to determine the form number
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.length + 1; // Increment by 1 for the new form
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
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImageBytes != null
                          ? MemoryImage(profileImageBytes)
                          : (_profileImageUrl != null &&
                          _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null),
                      child: (profileImageBytes == null &&
                          (_profileImageUrl == null ||
                              _profileImageUrl!.isEmpty))
                          ? Icon(Icons.person, size: 60, color: Colors.grey)
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _updateStatus(false),
                        child: const Text(
                          "Deny",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await generateEmployeePDF(user);
                    },
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      "Download PDF",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
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