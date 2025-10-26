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
        dobController.text =
            "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
        _calculateAge(pickedDate);
      });
    }
  }

  void _calculateAge(DateTime dob) {
    DateTime today = DateTime.now();
    int age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
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
            whatsapp: whatsappController.text,
            cameras: [],
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.blue[600]),
                    ),
                    Expanded(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              Expanded(
                child: _buildSignUpPage(),
              ),
            ],
          ),
        ),
      ),
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
            // Logo with enhanced styling
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset('assets/registeration.png', height: 120),
            ),

            SizedBox(height: 30),

            // Title with enhanced styling
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Welcome to SSM. Please fill in your details to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Form Container
            Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTextField("Name", nameController, false, null),
                  _buildTextField("Education Qualification",
                      qualificationController, false, null),
                  _buildTextField(
                      "Experience", experienceController, false, null),
                  Row(
                    children: [
                      Expanded(child: _buildDOBField()),
                      SizedBox(width: 12),
                      Expanded(
                          child: _buildTextField(
                              "Age", ageController, false, null)),
                    ],
                  ),
                  _buildGenderSelection(),
                  _buildTextField(
                      "Permanent Address", addressController, false, null),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                              "District", districtController, false, null)),
                      SizedBox(width: 12),
                      Expanded(
                          child: _buildTextField(
                              "State", stateController, false, null)),
                    ],
                  ),
                  _buildTextField("PinCode", pincodeController, false, null),
                  _buildTextField("Mobile Number *", mobileController, true,
                      _validateNumber),
                  _buildTextField("Alternative Mobile Number",
                      altMobileController, false, null),
                  _buildTextField(
                      "WhatsApp Number", whatsappController, false, null),

                  SizedBox(height: 30),

                  // Next Button
                  Container(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: Colors.blue.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _navigateToSecondPage,
                      child: Text(
                        "NEXT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
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

  Widget _buildTextField(String hint, TextEditingController controller,
      bool isRequired, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          labelStyle: TextStyle(color: Colors.blue[600]),
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
          labelText: "Date of Birth",
          hintText: "Select Date of Birth",
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          labelStyle: TextStyle(color: Colors.blue[600]),
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.blue[600]),
            onPressed: () => _selectDate(context),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Date of Birth is required" : null,
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gender",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
          SizedBox(height: 10),
          RadioListTile(
            value: "Male",
            groupValue: selectedGender,
            onChanged: (value) => setState(() => selectedGender = value!),
            title: Text("Male", style: TextStyle(color: Colors.blue[700])),
            activeColor: Colors.blue[600],
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile(
            value: "Female",
            groupValue: selectedGender,
            onChanged: (value) => setState(() => selectedGender = value!),
            title: Text("Female", style: TextStyle(color: Colors.blue[700])),
            activeColor: Colors.blue[600],
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile(
            value: "Other",
            groupValue: selectedGender,
            onChanged: (value) => setState(() => selectedGender = value!),
            title: Text("Other", style: TextStyle(color: Colors.blue[700])),
            activeColor: Colors.blue[600],
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  final List cameras;
  final String name,
      qualification,
      experience,
      dob,
      age,
      gender,
      address,
      district,
      state,
      pincode,
      mobile,
      altMobile,
      whatsapp;

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
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController emergencyContactController =
      TextEditingController();
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

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Enter a valid email address";
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
    if (passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password fields cannot be empty")),
      );
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    String email = emailController.text.trim();
    String mobile = widget.mobile.trim();

    // Check if email is provided and already exists
    if (email.isNotEmpty) {
      bool emailExists = await _isEmailAlreadyRegistered(email);
      if (emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Email is already registered")),
        );
        return;
      }
    }

    // Check if mobile is already registered
    bool mobileExists = await _isMobileAlreadyRegistered(mobile);
    if (mobileExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mobile number is already registered")),
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
            cameras: (widget.cameras as List)
                .map((e) => e as CameraDescription)
                .toList(),
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

  Future<bool> _isMobileAlreadyRegistered(String mobile) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('mobile', isEqualTo: mobile)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.blue[600]),
                    ),
                    Expanded(
                      child: Text(
                        "Sign Up - Step 2",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo with enhanced styling
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/registeration.png',
                              height: 120),
                        ),

                        SizedBox(height: 30),

                        // Title with enhanced styling
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Sign Up - Step 2",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Welcome To the SSM. Please complete your profile",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),

                        // Form Container
                        Container(
                          padding: EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ..._buildAdditionalTextFields(),
                              SizedBox(height: 30),

                              // Next Button
                              Container(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: Colors.blue.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _validateAndProceed();
                                    }
                                  },
                                  child: Text(
                                    "NEXT",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      bool isVisible, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          labelStyle: TextStyle(color: Colors.blue[600]),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.blue[600],
            ),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAdditionalTextFields() {
    return [
      _buildTextField("Native", nativeController, false, null),
      _buildTextField("Religion", religionController, false, null),
      _buildTextField("Cast", castController, false, null),
      _buildTextField(
          "Email ID (Optional)", emailController, false, _validateEmail),
      _buildPasswordField("Password", passwordController, _passwordVisible, () {
        setState(() {
          _passwordVisible = !_passwordVisible;
        });
      }),
      _buildPasswordField("Confirm Password", confirmPasswordController,
          _confirmPasswordVisible, () {
        setState(() {
          _confirmPasswordVisible = !_confirmPasswordVisible;
        });
      }),
      _buildTextField(
          "Emergency Contact No", emergencyContactController, false, null),
      _buildTextField("Blood Group", bloodGroupController, false, null),
      _buildTextField("Father Name", fatherNameController, false, null),
      _buildTextField(
          "Father Mobile Number", fatherMobileController, false, null),
      _buildTextField("Mother Name", motherNameController, false, null),
      _buildTextField(
          "Mother Mobile Number", motherMobileController, false, null),
      _buildTextField("Spouse Name", spouseNameController, false, null),
      _buildTextField(
          "Spouse Mobile Number", spouseMobileController, false, null),
    ];
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      bool isRequired, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          labelStyle: TextStyle(color: Colors.blue[600]),
        ),
        validator: isRequired ? validator : null,
      ),
    );
  }
}

class ThirdPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String name,
      qualification,
      experience,
      dob,
      age,
      gender,
      address,
      district,
      state,
      pincode,
      mobile,
      altMobile,
      whatsapp;
  final String native,
      religion,
      cast,
      email,
      password,
      emergencyContact,
      bloodGroup,
      fatherName,
      fatherMobile,
      motherName,
      motherMobile,
      spouseName,
      spouseMobile;

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
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text(
              "Registration Successful",
              style: TextStyle(
                color: Colors.green[800],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your registration has been completed successfully!",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty,
                      color: Colors.orange[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Your account is pending admin verification. You'll be able to log in once approved.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text(
              "Go to Login",
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to send OneSignal notification
  Future<void> _sendNotification(String userId, String userName) async {
    const String oneSignalAppId = "db2613bd-3067-4383-9f88-960b277c11aa";
    const String oneSignalApiKey =
        "os_v2_app_3mtbhpjqm5byhh4isyfso7arvicd2ew4ctiumpvngm4fc7zhksqa44rmmxdbwn5yavmszrcr3niiyvogldvfbpzor5pvnb6wwvang5y"; // Found in OneSignal settings

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

    // Validate required images
    if (_frontAadharImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload Front Aadhar image")),
      );
      return;
    }

    if (_backAadharImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload Back Aadhar image")),
      );
      return;
    }

    if (_signatureImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload Signature image")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential? userCredential;
      User? user;

      // Handle Firebase Authentication based on available credentials
      if (widget.email.isNotEmpty) {
        // User has email - create account with email
        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );
        user = userCredential.user;

        if (user != null) {
          // Send email verification
          await user.sendEmailVerification();
        }
      } else {
        // User doesn't have email - create anonymous account first
        userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
      }

      if (user != null) {
        // Note: Phone number linking will be handled during login process
        // For now, we store the mobile number in Firestore for login purposes

        // Store user data in Firestore
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "Eid": user.uid, // Store user ID
          "name": widget.name,
          "qualification": widget.qualification,
          "experience": widget.experience,
          "dob": widget.dob,
          "age": widget.age,
          "gender": widget.gender,
          "address": widget.address,
          "district": widget.district,
          "state": widget.state,
          "pincode": widget.pincode,
          "mobile": widget.mobile,
          "phone": widget.mobile, // Also store as phone for login
          "altMobile": widget.altMobile,
          "whatsapp": widget.whatsapp,
          "native": widget.native,
          "religion": widget.religion,
          "cast": widget.cast,
          "email": widget.email,
          "password": widget.password,
          "emergencyContact": widget.emergencyContact,
          "bloodGroup": widget.bloodGroup,
          "fatherName": widget.fatherName,
          "fatherMobile": widget.fatherMobile,
          "motherName": widget.motherName,
          "motherMobile": widget.motherMobile,
          "spouseName": widget.spouseName,
          "spouseMobile": widget.spouseMobile,
          "aadhar": aadharController.text,
          "pan": panController.text,
          "epf": epfController.text,
          "esi": esiController.text,
          "bank_name": bankNameController.text,
          "account_holder": accountHolderController.text,
          "account_number": accountNumberController.text,
          "ifsc": ifscController.text.length == 11
              ? ifscController.text
              : "INVALID_IFSC",
          "front_aadhar_image_bitcode": _frontAadharBitCode ?? "",
          "back_aadhar_image_bitcode": _backAadharBitCode ?? "",
          "signature_image_bitcode": _signatureBitCode ?? "",
          "timestamp": FieldValue.serverTimestamp(),
          "status": false,
        });

        await _sendNotification(user.uid, widget.name);

        // Sign out the user immediately after registration to prevent auto-login
        await FirebaseAuth.instance.signOut();
        print('User signed out after registration to prevent auto-login');

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

  Widget _buildTextField(String hint, TextEditingController controller,
      bool isRequired, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          labelStyle: TextStyle(color: Colors.blue[600]),
        ),
        validator: isRequired ? validator : null,
      ),
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aadhaar Front Upload
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload Aadhaar Front *",
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              _frontAadharImage != null
                  ? Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            Image.file(_frontAadharImage!, fit: BoxFit.cover),
                      ),
                    )
                  : Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          "No image selected",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _pickImage(ImageSource.gallery, "front_aadhar"),
                  icon: Icon(Icons.upload, color: Colors.white),
                  label: Text("Upload Front Aadhaar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 15),

        // Aadhaar Back Upload
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload Aadhaar Back *",
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              _backAadharImage != null
                  ? Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_backAadharImage!, fit: BoxFit.cover),
                      ),
                    )
                  : Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          "No image selected",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _pickImage(ImageSource.gallery, "back_aadhar"),
                  icon: Icon(Icons.upload, color: Colors.white),
                  label: Text("Upload Back Aadhaar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 15),

        // Signature Upload
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload Signature *",
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              _signatureImage != null
                  ? Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_signatureImage!, fit: BoxFit.cover),
                      ),
                    )
                  : Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          "No image selected",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery, "signature"),
                  icon: Icon(Icons.upload, color: Colors.white),
                  label: Text("Upload Signature"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.blue[600]),
                    ),
                    Expanded(
                      child: Text(
                        "Sign Up - Final Step",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Logo with enhanced styling
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset('assets/registeration.png',
                                  height: 120),
                            ),

                            SizedBox(height: 30),

                            // Title with enhanced styling
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "Sign Up - Final Step",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Complete your registration with documents",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30),

                            // Form Container
                            Container(
                              padding: EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildTextField("Aadhar Number (Optional)",
                                      aadharController, false, null),
                                  _buildTextField(
                                      "PAN Number", panController, false, null),
                                  _buildTextField(
                                      "EPF Number", epfController, false, null),
                                  _buildTextField(
                                      "ESI Number", esiController, false, null),
                                  _buildTextField("Bank Name",
                                      bankNameController, false, null),
                                  _buildTextField("Account Holder Name",
                                      accountHolderController, false, null),
                                  _buildTextField("Account Number",
                                      accountNumberController, false, null),
                                  _buildTextField(
                                      "IFSC Code", ifscController, false, null),

                                  SizedBox(height: 20),

                                  // Document Upload Section
                                  _buildDocumentUploadSection(),

                                  SizedBox(height: 30),

                                  // Submit Button
                                  Container(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[600],
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor:
                                            Colors.blue.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      ),
                                      onPressed: _isLoading
                                          ? null
                                          : () => _storeUserData(context),
                                      child: _isLoading
                                          ? CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            )
                                          : Text(
                                              "SUBMIT",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue[600]!),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
