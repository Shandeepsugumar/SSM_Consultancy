import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'loginpage.dart';
import 'package:image/image.dart' as img;


class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildSignUpPage(),
    );
  }

  Widget _buildSignUpPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/registeration.png', height: 150),
          Text(
            "Sign UP",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900]),
          ),
          SizedBox(height: 10),
          Text(
            "Welcome To the SSM Please Sign Up To Continue",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 20),
          _buildTextField("Name", nameController, false, null),
          _buildTextField("Education Qualification", qualificationController, false, null),
          _buildTextField("Experience", experienceController, false, null),
          Row(
            children: [
              Expanded(child: _buildDOBField()),
              SizedBox(width: 8),
              Expanded(child: _buildAgeField()),
            ],
          ),
          _buildGenderSelection(),
          _buildTextField("Permanent Address", addressController, false, null),
          Row(
            children: [
              Expanded(child: _buildTextField("District", districtController, false, null)),
              SizedBox(width: 8),
              Expanded(child: _buildTextField("State", stateController, false, null)),
            ],
          ),
          _buildTextField("PinCode", pincodeController, false, null),
          _buildTextField("Mobile Number", mobileController, false, null),
          _buildTextField("Alternative Mobile Number", altMobileController, false, null),
          _buildTextField("WhatsApp Number", whatsappController, false, null),
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
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, bool isRequired, RegExp? pattern) {
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
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return "$hint is required";
          }
          if (pattern != null && value != null && value.isNotEmpty && !pattern.hasMatch(value)) {
            return "Enter a valid $hint";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDOBField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
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
      ),
    );
  }

  Widget _buildAgeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: ageController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: "Age",
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
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

  // Function to hash password
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
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
        const SnackBar(content: Text("Password fields cannot be empty")),
      );
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    String email = emailController.text.trim();
    bool emailExists = await _isEmailAlreadyRegistered(email);

    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email is already registered")),
      );
      return;
    }

    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

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
            emergencyContact: emergencyContactController.text,
            bloodGroup: bloodGroupController.text,
            fatherName: fatherNameController.text,
            fatherMobile: fatherMobileController.text,
            motherName: motherNameController.text,
            motherMobile: motherMobileController.text,
            spouseName: spouseNameController.text,
            spouseMobile: spouseMobileController.text,
            password: hashedPassword, // Pass hashed password
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
              onPressed: _validateAndProceed,
              child: const Text("NEXT", style: TextStyle(fontSize: 16)),
            ),
          ],
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
      _buildTextField("Native", nativeController),
      _buildTextField("Religion", religionController),
      _buildTextField("Cast", castController),
      _buildTextField("Email ID", emailController),
      _buildTextField("Emergency Contact No", emergencyContactController),
      _buildTextField("Blood Group", bloodGroupController),
      _buildTextField("Father Name", fatherNameController),
      _buildTextField("Father Mobile Number", fatherMobileController),
      _buildTextField("Mother Name", motherNameController),
      _buildTextField("Mother Mobile Number", motherMobileController),
      _buildTextField("Spouse Name", spouseNameController),
      _buildTextField("Spouse Mobile Number", spouseMobileController),
    ];
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
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



  // Function to store data in Firestore
  Future<void> _storeUserData(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection("users").add({
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

      _showSuccessDialog();
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



  Widget _buildTextField(String hint, TextEditingController controller, bool isRequired, RegExp? pattern) {
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
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return "$hint is required";
          }
          if (pattern != null && value != null && value.isNotEmpty && !pattern.hasMatch(value)) {
            return "Enter a valid $hint";
          }
          return null;
        },
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
                  _buildTextField("Aadhar Number (Optional)", aadharController, false, null),
                  _buildTextField("PAN Number", panController, false, null),
                  _buildTextField("EPF Number", epfController, false, null),
                  _buildTextField("ESI Number", esiController, false, null),
                  _buildTextField("Bank Name", bankNameController, false, null),
                  _buildTextField("Account Holder Name", accountHolderController, false, null),
                  _buildTextField("Account Number", accountNumberController, false, null),
                  _buildTextField("IFSC Code", ifscController, false, null),

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