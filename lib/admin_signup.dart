import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_login.dart';

class AdminSignupPage extends StatefulWidget {
  @override
  _AdminSignupPageState createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends State<AdminSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String _selectedGender = "";
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  /// **Hash password using SHA-256**
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// **Validate Form and Proceed**
  Future<void> _validateAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print("Admin User Created: ${userCredential.user!.uid}");
      await _storeAdminData(userCredential);
      _showSuccessDialog();
    } catch (e) {
      print("Firebase Auth Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _storeAdminData(UserCredential userCredential) async {
    try {
      CollectionReference adminsCollection =
          FirebaseFirestore.instance.collection("Admins");

      // Define the admin data
      Map<String, dynamic> newAdmin = {
        "uid": userCredential.user!.uid, // Store user ID
        "FirstName": _firstnameController.text.trim(),
        "LastName": _lastnameController.text.trim(),
        "Email": _emailController.text.trim(),
        "Password": _hashPassword(
            _passwordController.text.trim()), // Store hashed password
        "DateOfBirth": _dobController.text.trim(),
        "Age": _ageController.text.trim(),
        "PhoneNumber": _phoneNumberController.text.trim(),
        "Gender": _selectedGender,
        "timestamp": FieldValue.serverTimestamp(),
      };

      // Store each admin as a **separate document** with user UID
      await adminsCollection.doc(userCredential.user!.uid).set(newAdmin);

      print("Admin data stored successfully!");
    } catch (e) {
      print("Firestore Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firestore Error: ${e.toString()}")),
      );
    }
  }

  /// **Show Success Dialog**
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Admin Account Created"),
        content: const Text("Your admin account has been created successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminLoginPage()),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// **Pick Date of Birth**
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text =
            "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
        _calculateAge(pickedDate);
      });
    }
  }

  /// **Calculate Age Based on DOB**
  void _calculateAge(DateTime dob) {
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    _ageController.text = age.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Admin Account"),
        backgroundColor: Colors.blue[100],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Admin Icon
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 60,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(height: 20),
              
              _buildTextField("First Name", _firstnameController),
              _buildTextField("Last Name", _lastnameController),
              _buildTextField("Email", _emailController),
              _buildPasswordField(
                  "Password", _passwordController, _passwordVisible, () {
                setState(() => _passwordVisible = !_passwordVisible);
              }),
              _buildPasswordField("Confirm Password",
                  _confirmPasswordController, _confirmPasswordVisible, () {
                setState(
                    () => _confirmPasswordVisible = !_confirmPasswordVisible);
              }),
              _buildDOBField(),
              _buildTextField("Age", _ageController),
              _buildGenderSelection(),
              _buildTextField("Mobile Number", _phoneNumberController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _validateAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("CREATE ADMIN ACCOUNT", 
                           style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDOBField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: _dobController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: "Select Date of Birth",
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
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

  /// **Reusable Text Field**
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "$label is required" : null,
      ),
    );
  }

  /// **Password Field with Visibility Toggle**
  Widget _buildPasswordField(String label, TextEditingController controller,
      bool isVisible, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: toggleVisibility,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "$label is required";
          if (value.length < 6) return "Password must be at least 6 characters";
          return null;
        },
      ),
    );
  }

  /// **Gender Selection**
  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Gender",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        RadioListTile(
            value: "Male",
            groupValue: _selectedGender,
            onChanged: (value) => setState(() => _selectedGender = value!),
            title: Text("Male")),
        RadioListTile(
            value: "Female",
            groupValue: _selectedGender,
            onChanged: (value) => setState(() => _selectedGender = value!),
            title: Text("Female")),
        RadioListTile(
            value: "Other",
            groupValue: _selectedGender,
            onChanged: (value) => setState(() => _selectedGender = value!),
            title: Text("Other")),
        SizedBox(height: 15),
      ],
    );
  }
}