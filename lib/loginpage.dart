import 'package:consultancy/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'binary_password_helper.dart';
import 'session_manager.dart';
import 'admin_login.dart';

enum AuthMode { employee, admin }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  AuthMode _currentAuthMode = AuthMode.employee; // Default to employee login

  /// Helper function to check if the input is a mobile number
  bool _isMobileNumber(String input) {
    // Check if input contains only digits and is 10 digits long (adjust as needed)
    return RegExp(r'^\d{10}$').hasMatch(input) ||
        RegExp(r'^\+\d{10,15}$').hasMatch(input);
  }

  /// Helper function to check if the input is an email
  bool _isEmail(String input) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }

  /// Switch between Employee and Admin login modes
  void _toggleAuthMode() {
    setState(() {
      _currentAuthMode = _currentAuthMode == AuthMode.employee
          ? AuthMode.admin
          : AuthMode.employee;
      _errorMessage = null; // Clear any previous errors
      _emailOrPhoneController.clear();
      _passwordController.clear();
    });
  }

  /// Navigate to Admin Login Page
  void _navigateToAdminLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminLoginPage()),
    );
  }

  /// ✅ Binary Password Authentication Function - Supports Email and Mobile (Employee Login)
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Get entered credentials
      String enteredEmailOrPhone = _emailOrPhoneController.text.trim();
      String enteredPassword = _passwordController.text.trim();

      print('Attempting login for: $enteredEmailOrPhone');

      // Step 2: Determine if input is email or mobile number
      bool isEmail = _isEmail(enteredEmailOrPhone);
      bool isMobile = _isMobileNumber(enteredEmailOrPhone);

      if (!isEmail && !isMobile) {
        setState(() {
          _errorMessage = "Please enter a valid email or mobile number.";
        });
        return;
      }

      // Step 3: Find user by email or mobile number in users collection
      QuerySnapshot userQuery;

      if (isEmail) {
        print('Searching by email: $enteredEmailOrPhone');
        userQuery = await FirebaseFirestore.instance
            .collection("users")
            .where("email", isEqualTo: enteredEmailOrPhone)
            .limit(1)
            .get();
      } else {
        print('Searching by mobile: $enteredEmailOrPhone');
        userQuery = await FirebaseFirestore.instance
            .collection("users")
            .where("phone", isEqualTo: enteredEmailOrPhone)
            .limit(1)
            .get();
      }

      if (userQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = isEmail
              ? "No user found with this email address."
              : "No user found with this mobile number.";
        });
        return;
      }

      // Step 4: Get user document
      DocumentSnapshot userDoc = userQuery.docs.first;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      print('Found user: ${userData['name']}');
      print('User doc ID: ${userDoc.id}');

      // Step 5: Verify password against stored hash
      String storedPasswordHash = userData['password'] ?? '';
      print('Stored password hash: $storedPasswordHash');

      bool passwordMatches = BinaryPasswordHelper.verifyPasswordHash(
          enteredPassword, storedPasswordHash);
      print('Password verification result: $passwordMatches');

      if (!passwordMatches) {
        setState(() {
          _errorMessage = "Incorrect password.";
        });
        return;
      }

      // ✅ Step 5.5: Check user verification status
      bool isVerified = userData['status'] ?? false;
      print('User verification status: $isVerified');

      if (!isVerified) {
        setState(() {
          _errorMessage =
              "Your account is pending admin verification. Please wait for admin approval before logging in.";
        });
        // Show detailed dialog for pending verification
        _showVerificationPendingDialog();
        return;
      }

      // Step 6: Handle Firebase Auth differently for email vs mobile
      String customUid = userDoc.id;
      print('Custom UID: $customUid');

      User? currentFirebaseUser;

      if (isEmail) {
        // For email login, try Firebase Auth
        try {
          UserCredential userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: enteredEmailOrPhone,
            password: enteredPassword,
          );
          currentFirebaseUser = userCredential.user;
          print(
              'Existing Firebase Auth user found: ${currentFirebaseUser?.uid}');
        } catch (e) {
          print('Firebase Auth user not found, will create new one');

          // Create Firebase Auth user if doesn't exist
          try {
            UserCredential newUserCredential =
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: enteredEmailOrPhone,
              password: enteredPassword,
            );
            currentFirebaseUser = newUserCredential.user;
            print(
                'Created new Firebase Auth user: ${currentFirebaseUser?.uid}');

            // Create UID mapping
            if (currentFirebaseUser != null) {
              await FirebaseFirestore.instance
                  .collection("uid_mapping")
                  .doc(currentFirebaseUser.uid)
                  .set({
                'originalAuthUid': currentFirebaseUser.uid,
                'customUid': customUid,
                'createdAt': DateTime.now(),
              });
              print('Created UID mapping for new user');
            }
          } catch (authError) {
            print('Error creating Firebase Auth user: $authError');
            // Continue with login even if Firebase Auth fails
          }
        }
      } else {
        // For mobile login, try to find existing Firebase user or create anonymous
        try {
          // First try to find if user exists in Firebase Auth with phone
          // This is a simplified approach - in production you'd want to link phone numbers
          UserCredential userCredential =
              await FirebaseAuth.instance.signInAnonymously();
          currentFirebaseUser = userCredential.user;
          print(
              'Signed in anonymously for mobile user: ${currentFirebaseUser?.uid}');

          // Create UID mapping for anonymous user
          if (currentFirebaseUser != null) {
            await FirebaseFirestore.instance
                .collection("uid_mapping")
                .doc(currentFirebaseUser.uid)
                .set({
              'originalAuthUid': currentFirebaseUser.uid,
              'customUid': customUid,
              'loginMethod': 'mobile',
              'mobileNumber': enteredEmailOrPhone,
              'createdAt': DateTime.now(),
            });
            print('Created UID mapping for mobile user');
          }
        } catch (authError) {
          print('Error with anonymous authentication: $authError');
          // Continue with login even if Firebase Auth fails
        }
      }

      // Step 7: Save user session for app state management
      await SessionManager.saveUserSession(
        customUid: customUid,
        email: userData['email'] ?? enteredEmailOrPhone,
        name: userData['name'] ?? 'Unknown',
      );

      // Step 8: Navigate to appropriate Home Page based on auth mode
      print('Login successful for user: ${userData['name']}');
      if (_currentAuthMode == AuthMode.employee) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // This shouldn't happen as admin login is handled separately
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      print('Unexpected error during login: $e');
      setState(() {
        _errorMessage = "An unexpected error occurred: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Show dialog when user account is pending verification
  void _showVerificationPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                "Verification Pending",
                style: TextStyle(
                  color: Colors.orange[800],
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
                "Your account is currently under review by our admin team.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                "Please wait for admin approval before you can access the application.",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You will be notified once your account is verified.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
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
                Navigator.of(context).pop();
              },
              child: Text(
                "OK",
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  void _checkIfLoggedIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check both Firebase Auth and our custom session
      final user = FirebaseAuth.instance.currentUser;
      final sessionLoggedIn = await SessionManager.isUserLoggedIn();

      if (user != null && sessionLoggedIn) {
        // Get current user UID from session
        String? customUid = await SessionManager.getCurrentUserUid();

        if (customUid != null) {
          // Check user verification status in Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(customUid)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            bool isVerified = userData['status'] ?? false;

            if (isVerified) {
              // User is verified, go to HomePage
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              });
              return;
            } else {
              // User exists but not verified, clear session and stay on login
              await SessionManager.clearUserSession();
              await FirebaseAuth.instance.signOut();
              print('User not verified, cleared session');
            }
          }
        }
      }
    } catch (e) {
      print('Error checking login status: $e');
      // Clear any corrupted session data
      await SessionManager.clearUserSession();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
                SizedBox(height: 20),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
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
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 20.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

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
                        child:
                            Image.asset('assets/login_page.webp', height: 120),
                      ),

                      const SizedBox(height: 40),

                      // Title with enhanced styling
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                              _currentAuthMode == AuthMode.employee
                                  ? 'Employee Login'
                                  : 'Admin Login',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentAuthMode == AuthMode.employee
                                  ? 'Welcome To SSM. Login with Email or Mobile Number'
                                  : 'Admin Access - Login with Email',
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
                      const SizedBox(height: 30),

                      // Auth Mode Toggle Button
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_currentAuthMode !=
                                          AuthMode.employee) {
                                        _toggleAuthMode();
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _currentAuthMode ==
                                                AuthMode.employee
                                            ? Colors.blue[600]
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Employee',
                                        style: TextStyle(
                                          color: _currentAuthMode ==
                                                  AuthMode.employee
                                              ? Colors.white
                                              : Colors.blue[600],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (_currentAuthMode != AuthMode.admin) {
                                        _navigateToAdminLogin();
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color:
                                            _currentAuthMode == AuthMode.admin
                                                ? Colors.blue[600]
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Admin',
                                        style: TextStyle(
                                          color:
                                              _currentAuthMode == AuthMode.admin
                                                  ? Colors.white
                                                  : Colors.blue[600],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
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
                      const SizedBox(height: 20),

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
                            // Email/Mobile Field
                            TextFormField(
                              controller: _emailOrPhoneController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email or Mobile Number',
                                hintText:
                                    'Enter email or 10-digit mobile number',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      BorderSide(color: Colors.blue[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      BorderSide(color: Colors.blue[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color: Colors.blue[600]!, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 18),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Colors.blue[600],
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email or mobile number';
                                }

                                bool isValidEmail = _isEmail(value);
                                bool isValidMobile = _isMobileNumber(value);

                                if (!isValidEmail && !isValidMobile) {
                                  return 'Enter a valid email or 10-digit mobile number';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Field with Visibility Toggle
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      BorderSide(color: Colors.blue[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      BorderSide(color: Colors.blue[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color: Colors.blue[600]!, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 18),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Colors.blue[600],
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.blue[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),

                            // Display Firebase Errors
                            if (_errorMessage != null)
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red[600], size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 20),

                            // Login Button
                            Container(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : (_currentAuthMode == AuthMode.employee
                                        ? _loginUser
                                        : _navigateToAdminLogin),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: Colors.blue.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      )
                                    : Text(
                                        _currentAuthMode == AuthMode.employee
                                            ? 'LOGIN'
                                            : 'ADMIN LOGIN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an Account? ",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => FirstPage()),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            // Forgot Password
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ForgotPasswordScreen()),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom spacing to ensure content is visible when scrolled
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailOrPhoneController = TextEditingController();
  final TextEditingController smsCodeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isSmsVerification = false;
  bool _isPasswordReset = false;
  String? _verificationId;
  String? _errorMessage;

  /// Helper function to check if the input is a mobile number
  bool _isMobileNumber(String input) {
    return RegExp(r'^\d{10}$').hasMatch(input) ||
        RegExp(r'^\+\d{10,15}$').hasMatch(input);
  }

  /// Helper function to check if the input is an email
  bool _isEmail(String input) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }

  void resetPassword() async {
    String emailOrPhone = emailOrPhoneController.text.trim();
    if (emailOrPhone.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email or mobile number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool isEmail = _isEmail(emailOrPhone);
      bool isMobile = _isMobileNumber(emailOrPhone);

      if (!isEmail && !isMobile) {
        setState(() {
          _errorMessage = 'Please enter a valid email or mobile number';
        });
        return;
      }

      if (isEmail) {
        // Handle email password reset
        await _auth.sendPasswordResetEmail(email: emailOrPhone);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Password reset email sent! Check your inbox.')),
        );
        Navigator.pop(context);
      } else {
        // Handle SMS verification for mobile
        await _auth.verifyPhoneNumber(
          phoneNumber:
              emailOrPhone.startsWith('+') ? emailOrPhone : '+91$emailOrPhone',
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification completed
            await _verifySmsCode(credential.smsCode!);
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() {
              _errorMessage = 'SMS verification failed: ${e.message}';
            });
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _isSmsVerification = true;
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifySmsCode(String smsCode) async {
    if (_verificationId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // Sign in with the credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        setState(() {
          _isPasswordReset = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid verification code';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPasswordController.text);

        // Update password in Firestore as well
        String? customUid = await SessionManager.getCurrentUserUid();
        if (customUid != null) {
          String hashedPassword = BinaryPasswordHelper.generateHashPassword(
              newPasswordController.text);
          await FirebaseFirestore.instance
              .collection("users")
              .doc(customUid)
              .update({'password': hashedPassword});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully!')),
        );

        // Sign out and return to login
        await _auth.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating password: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
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
                  child: Icon(
                    Icons.lock_reset,
                    size: 60,
                    color: Colors.blue[600],
                  ),
                ),

                SizedBox(height: 30),

                // Title
                Text(
                  _isPasswordReset ? 'Set New Password' : 'Reset Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  _isPasswordReset
                      ? 'Enter your new password'
                      : _isSmsVerification
                          ? 'Enter the verification code sent to your mobile'
                          : 'Enter your email or mobile number to reset password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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
                      if (!_isPasswordReset && !_isSmsVerification) ...[
                        // Email/Phone Input
                        TextFormField(
                          controller: emailOrPhoneController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email or Mobile Number',
                            hintText: 'Enter email or 10-digit mobile number',
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
                              borderSide: BorderSide(
                                  color: Colors.blue[600]!, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            prefixIcon: Icon(Icons.person_outline,
                                color: Colors.blue[600]),
                          ),
                        ),
                      ] else if (_isSmsVerification && !_isPasswordReset) ...[
                        // SMS Code Input
                        TextFormField(
                          controller: smsCodeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Verification Code',
                            hintText: 'Enter 6-digit code',
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
                              borderSide: BorderSide(
                                  color: Colors.blue[600]!, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            prefixIcon:
                                Icon(Icons.sms, color: Colors.blue[600]),
                          ),
                        ),
                      ] else if (_isPasswordReset) ...[
                        // New Password Input
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'New Password',
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
                              borderSide: BorderSide(
                                  color: Colors.blue[600]!, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            prefixIcon: Icon(Icons.lock_outline,
                                color: Colors.blue[600]),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Confirm Password Input
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
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
                              borderSide: BorderSide(
                                  color: Colors.blue[600]!, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            prefixIcon: Icon(Icons.lock_outline,
                                color: Colors.blue[600]),
                          ),
                        ),
                      ],

                      SizedBox(height: 20),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red[600], size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                      color: Colors.red[700], fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 20),

                      // Action Button
                      Container(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_isPasswordReset) {
                                    _updatePassword();
                                  } else if (_isSmsVerification) {
                                    _verifySmsCode(smsCodeController.text);
                                  } else {
                                    resetPassword();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: Colors.blue.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : Text(
                                  _isPasswordReset
                                      ? 'UPDATE PASSWORD'
                                      : _isSmsVerification
                                          ? 'VERIFY CODE'
                                          : 'SEND RESET',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Back to Login
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to Login',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
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
    );
  }
}
