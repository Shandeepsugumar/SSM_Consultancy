import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'loginpage.dart';
import 'package:image/image.dart' as img;
import 'package:onesignal_flutter/onesignal_flutter.dart';


class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController qualificationController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController altMobileController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();

  String selectedGender = "";

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text = "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
        _calculateAge(pickedDate);
      });
    }
  }

  void _calculateAge(DateTime dob) {
    DateTime today = DateTime.now();
    int age = today.year - dob.year;

    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    ageController.text = age.toString();
  }

  void _navigateToSecondPage() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, proceed to the next page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecondPage(
            name: nameController.text,
            qualification: qualificationController.text,
            experience: experienceController.text,
            dob: dobController.text,
            age: ageController.text,
            gender: selectedGender,
            address: addressController.text,
            district: districtController.text,
            state: stateController.text,
            pincode: pincodeController.text,
            mobile: mobileController.text,
            altMobile: altMobileController.text,
            whatsapp: whatsappController.text, cameras: [],
          ),
        ),
      );
    }
  }
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    }
    return null;
  }


  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Name is required";
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return "Name should only contain letters";
    }
    return null;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return "Enter a valid 10-digit number";
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Age is required";
    } else if (int.tryParse(value)! < 18) {
      return "Age must be at least 18";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: _buildSignUpPage(),
    );
  }

  Widget _buildSignUpPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/registeration.png', height: 150),
            Text(
              "Sign UP",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900]),
            ),
            SizedBox(height: 20),
            _buildTextField("Name", nameController, true, _validateName),
            _buildTextField("Education Qualification", qualificationController, true, _validateRequired),
            _buildTextField("Experience", experienceController, true, _validateRequired),
            Row(
              children: [
                Expanded(child: _buildDOBField()),
                SizedBox(width: 8),
                Expanded(child: _buildTextField("Age", ageController, true, _validateAge)),
              ],
            ),
            _buildGenderSelection(),
            _buildTextField("Permanent Address", addressController, true, _validateRequired),
            Row(
              children: [
                Expanded(child: _buildTextField("District", districtController, true, _validateRequired)),
                SizedBox(width: 8),
                Expanded(child: _buildTextField("State", stateController, true, _validateRequired)),
              ],
            ),
            _buildTextField("PinCode", pincodeController, true, null),
            _buildTextField("Mobile Number", mobileController, true, _validateNumber),
            _buildTextField("Alternative Mobile Number", altMobileController, true, _validateNumber),
            _buildTextField("WhatsApp Number", whatsappController, true, _validateNumber),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF00008B),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _navigateToSecondPage,
              child: Text("NEXT", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, bool isRequired, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: isRequired ? validator : null,
      ),
    );
  }

  Widget _buildDOBField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: dobController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: "Select Date of Birth",
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.blue),
            onPressed: () => _selectDate(context),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? "Date of Birth is required" : null,
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 5),
          child: Text("Gender", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        RadioListTile(
          value: "Male",
          groupValue: selectedGender,
          onChanged: (value) => setState(() => selectedGender = value!),
          title: Text("Male"),
        ),
        RadioListTile(
          value: "Female",
          groupValue: selectedGender,
          onChanged: (value) => setState(() => selectedGender = value!),
          title: Text("Female"),
        ),
        RadioListTile(
          value: "Other",
          groupValue: selectedGender,
          onChanged: (value) => setState(() => selectedGender = value!),
          title: Text("Other"),
        ),
      ],
    );
  }
}



class SecondPage extends StatefulWidget {
  final List cameras;
  final String name, qualification, experience, dob, age, gender, address, district, state, pincode, mobile, altMobile, whatsapp;

  SecondPage({
    required this.cameras,
    required this.name,
    required this.qualification,
    required this.experience,
    required this.dob,
    required this.age,
    required this.gender,
    required this.address,
    required this.district,
    required this.state,
    required this.pincode,
    required this.mobile,
    required this.altMobile,
    required this.whatsapp,
    Key? key,
  }) : super(key: key);

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final TextEditingController nativeController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
  final TextEditingController castController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController fatherMobileController = TextEditingController();
  final TextEditingController motherNameController = TextEditingController();
  final TextEditingController motherMobileController = TextEditingController();
  final TextEditingController spouseNameController = TextEditingController();
  final TextEditingController spouseMobileController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>(); // Create a Form key

  // Function to hash password
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    }
    return null;
  }
  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return "Enter a valid 10-digit number";
    }
    return null;
  }
  
  Future<bool> _isEmailAlreadyRegistered(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _validateAndProceed() async {
    if (passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password fields cannot be empty")),
      );
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text( "Passwords do not match")),
      );
      return;
    }

    String email = emailController.text.trim();
    bool emailExists = await _isEmailAlreadyRegistered(email);

    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email is already registered")),
      );
      return;
    }

    try {

      // Store user details in Firestore with hashed password
      String hashedPassword = _hashPassword(passwordController.text.trim());

      // Navigate to ThirdPage after successful sign-up
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ThirdPage(
            cameras: (widget.cameras as List).map((e) => e as CameraDescription).toList(),
            name: widget.name,
            qualification: widget.qualification,
            experience: widget.experience,
            dob: widget.dob,
            age: widget.age,
            gender: widget.gender,
            address: widget.address,
            district: widget.district,
            state: widget.state,
            pincode: widget.pincode,
            mobile: widget.mobile,
            altMobile: widget.altMobile,
            whatsapp: widget.whatsapp,
            native: nativeController.text,
            religion: religionController.text,
            cast: castController.text,
            email: emailController.text,
            password: hashedPassword, // Pass hashed password
            emergencyContact: emergencyContactController.text,
            bloodGroup: bloodGroupController.text,
            fatherName: fatherNameController.text,
            fatherMobile: fatherMobileController.text,
            motherName: motherNameController.text,
            motherMobile: motherMobileController.text,
            spouseName: spouseNameController.text,
            spouseMobile: spouseMobileController.text,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form( // Wrap fields inside a Form widget
          key: _formKey, // Assign the GlobalKey
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/registeration.png', height: 150),
              const SizedBox(height: 10),
              Text(
                "Sign UP",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Welcome To the SSM. Please Sign Up To Continue",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ..._buildAdditionalTextFields(),

              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF00008B),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) { // Validate form fields
                    _validateAndProceed();
                  }
                },
                child: const Text("NEXT", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isVisible, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAdditionalTextFields() {
    return [
      _buildTextField("Native", nativeController,true,_validateRequired),
      _buildTextField("Religion", religionController,true,_validateRequired),
      _buildTextField("Cast", castController,true,_validateRequired),
      _buildTextField("Email ID", emailController,true,_validateRequired),
      _buildPasswordField("Password", passwordController, _passwordVisible, () {
        setState(() {
          _passwordVisible = !_passwordVisible;
        });
      }),
      _buildPasswordField("Confirm Password", confirmPasswordController, _confirmPasswordVisible, () {
        setState(() {
          _confirmPasswordVisible = !_confirmPasswordVisible;
        });
      }),
      _buildTextField("Emergency Contact No", emergencyContactController,true,_validateRequired),
      _buildTextField("Blood Group", bloodGroupController,true,_validateRequired),
      _buildTextField("Father Name", fatherNameController,true,_validateRequired),
      _buildTextField("Father Mobile Number", fatherMobileController,true,_validateNumber),
      _buildTextField("Mother Name", motherNameController,true,_validateRequired),
      _buildTextField("Mother Mobile Number", motherMobileController,true,_validateNumber),
      _buildTextField("Spouse Name", spouseNameController,true,_validateRequired),
      _buildTextField("Spouse Mobile Number", spouseMobileController,true,_validateNumber),
    ];
  }

  Widget _buildTextField(String hint, TextEditingController controller, bool isRequired, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: isRequired ? validator : null,
      ),
    );
  }
}


class ThirdPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String name, qualification, experience, dob, age, gender, address,
      district, state, pincode, mobile, altMobile, whatsapp;
  final String native, religion, cast, email, password, emergencyContact,
      bloodGroup, fatherName, fatherMobile, motherName, motherMobile, spouseName, spouseMobile;

  ThirdPage({
    required this.cameras,
    required this.name,
    required this.qualification,
    required this.experience,
    required this.dob,
    required this.age,
    required this.gender,
    required this.address,
    required this.district,
    required this.state,
    required this.pincode,
    required this.mobile,
    required this.altMobile,
    required this.whatsapp,
    required this.native,
    required this.religion,
    required this.cast,
    required this.email,
    required this.password,
    required this.emergencyContact,
    required this.bloodGroup,
    required this.fatherName,
    required this.fatherMobile,
    required this.motherName,
    required this.motherMobile,
    required this.spouseName,
    required this.spouseMobile,
  });

  @override
  _ThirdPageState createState() => _ThirdPageState();
}
class _ThirdPageState extends State<ThirdPage> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for Text Fields
  final TextEditingController aadharController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController epfController = TextEditingController();
  final TextEditingController esiController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountHolderController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();

  String? _frontAadharBitCode;
  String? _backAadharBitCode;
  String? _signatureBitCode;

  File? _frontAadharImage;
  File? _backAadharImage;
  File? _signatureImage;

  bool _isLoading = false; // Loading state

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    }
    return null;
  }
  // Convert image to Base64
  Future<String> _convertImageToBase64(File image) async {
    final bytes = await image.readAsBytes();

    // Resize Image
    img.Image? originalImage = img.decodeImage(bytes);
    img.Image resizedImage = img.copyResize(originalImage!, width: 300);

    final resizedBytes = img.encodeJpg(resizedImage, quality: 85);
    return base64Encode(resizedBytes);
  }

  // Function to pick image
  Future<void> _pickImage(ImageSource source, String type) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String base64String = await _convertImageToBase64(imageFile);

      setState(() {
        if (type == "front_aadhar") {
          _frontAadharBitCode = base64String;
          _frontAadharImage = imageFile;
        } else if (type == "back_aadhar") {
          _backAadharBitCode = base64String;
          _backAadharImage = imageFile;
        } else if (type == "signature") {
          _signatureBitCode = base64String;
          _signatureImage = imageFile;
        }
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Up Completed"),
        content: const Text("Your information has been stored successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  // Function to send OneSignal notification
  Future<void> _sendNotification(String userId, String userName) async {
    const String oneSignalAppId = "db2613bd-3067-4383-9f88-960b277c11aa";
    const String oneSignalApiKey = "os_v2_app_3mtbhpjqm5byhh4isyfso7arvicd2ew4ctiumpvngm4fc7zhksqa44rmmxdbwn5yavmszrcr3niiyvogldvfbpzor5pvnb6wwvang5y"; // Found in OneSignal settings

    final Map<String, dynamic> notificationData = {
      "app_id": oneSignalAppId,
      "include_external_user_ids": [userId], // Send to specific user
      "headings": {"en": "Sign Up Successful"},
      "contents": {"en": "Hello $userName, your registration is successful!"},
    };

    final response = await http.post(
      Uri.parse("https://onesignal.com/api/v1/notifications"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Basic $oneSignalApiKey",
      },
      body: jsonEncode(notificationData),
    );

    if (response.statusCode == 200) {
      print("Notification sent successfully!");
    } else {
      print("Failed to send notification: ${response.body}");
    }
  }
  // Function to store data in Firestore
  Future<void> _storeUserData(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Register the user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email!,
        password: widget.password!,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Store user data in Firestore
        await FirebaseFirestore.instance.collection("users").doc(userCredential.user!.uid).set({
          "uid": userCredential.user!.uid, // Store user ID
          "name": widget.name ?? "Unknown",
          "qualification": widget.qualification ?? "Unknown",
          "experience": widget.experience ?? "0 years",
          "dob": widget.dob ?? "",
          "age": widget.age ?? "",
          "gender": widget.gender ?? "",
          "address": widget.address ?? "",
          "district": widget.district ?? "",
          "state": widget.state ?? "",
          "pincode": widget.pincode ?? "",
          "mobile": widget.mobile ?? "",
          "altMobile": widget.altMobile ?? "",
          "whatsapp": widget.whatsapp ?? "",
          "native": widget.native ?? "",
          "religion": widget.religion ?? "",
          "cast": widget.cast ?? "",
          "email": widget.email ?? "",
          "password": widget.password ?? "",
          "emergencyContact": widget.emergencyContact ?? "",
          "bloodGroup": widget.bloodGroup ?? "",
          "fatherName": widget.fatherName ?? "",
          "fatherMobile": widget.fatherMobile ?? "",
          "motherName": widget.motherName ?? "",
          "motherMobile": widget.motherMobile ?? "",
          "spouseName": widget.spouseName ?? "",
          "spouseMobile": widget.spouseMobile ?? "",
          "aadhar": aadharController.text,
          "pan": panController.text,
          "epf": epfController.text,
          "esi": esiController.text,
          "bank_name": bankNameController.text,
          "account_holder": accountHolderController.text,
          "account_number": accountNumberController.text,
          "ifsc": ifscController.text.length == 11 ? ifscController.text : "INVALID_IFSC",
          "front_aadhar_image_bitcode": _frontAadharBitCode ?? "",
          "back_aadhar_image_bitcode": _backAadharBitCode ?? "",
          "signature_image_bitcode": _signatureBitCode ?? "",
          "timestamp": FieldValue.serverTimestamp(),
          "status": false,
        });

        await _sendNotification(user.uid, widget.name ?? "User");
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.message}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Auth Error: ${e.message}")),
      );

      setState(() => _isLoading = false);
      return;
    } on FirebaseException catch (e) {
      print("Firestore Error: ${e.message}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Database Error: ${e.message}")),
      );

      setState(() => _isLoading = false);
      return;
    } catch (error) {
      print("Error storing data: $error");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to store data. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Widget _buildTextField(String hint, TextEditingController controller, bool isRequired, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: isRequired ? validator : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('assets/registeration.png', height: 150),
                  _buildTextField("Aadhar Number (Optional)", aadharController, true, _validateRequired),
                  _buildTextField("PAN Number", panController, true, _validateRequired),
                  _buildTextField("EPF Number", epfController, true, _validateRequired),
                  _buildTextField("ESI Number", esiController, true, _validateRequired),
                  _buildTextField("Bank Name", bankNameController, true, _validateRequired),
                  _buildTextField("Account Holder Name", accountHolderController, true, _validateRequired),
                  _buildTextField("Account Number", accountNumberController, true, _validateRequired),
                  _buildTextField("IFSC Code", ifscController, true, _validateRequired),

                  SizedBox(height: 10),

                  Text("Upload Aadhaar Front"),
                  _frontAadharImage != null
                      ? Image.file(_frontAadharImage!, height: 100)
                      : Text("No image selected"),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery, "front_aadhar"),
                    child: Text("Upload Front Aadhaar"),
                  ),

                  SizedBox(height: 10),

                  Text("Upload Aadhaar Back"),
                  _backAadharImage != null
                      ? Image.file(_backAadharImage!, height: 100)
                      : Text("No image selected"),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery, "back_aadhar"),
                    child: Text("Upload Back Aadhaar"),
                  ),

                  SizedBox(height: 10),

                  Text("Upload Signature"),
                  _signatureImage != null
                      ? Image.file(_signatureImage!, height: 100)
                      : Text("No image selected"),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery, "signature"),
                    child: Text("Upload Signature"),
                  ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _storeUserData(context),
                    child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text("SUBMIT"),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}