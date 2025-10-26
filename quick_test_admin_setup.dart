// Quick Admin Setup and Testing Script
// Run this once to set up your admin account and test the system

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuickAdminSetup extends StatefulWidget {
  @override
  _QuickAdminSetupState createState() => _QuickAdminSetupState();
}

class _QuickAdminSetupState extends State<QuickAdminSetup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _status = 'Ready to setup admin';
  bool _isLoading = false;

  // Step 1: Create Admin Account
  Future<void> createAdminAccount() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating admin account...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _status = 'Error: No user logged in. Please login first.';
        });
        return;
      }

      // Create admin record
      await _firestore.collection('admins').doc(user.uid).set({
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'email': user.email,
      });

      setState(() {
        _status = 'Admin account created successfully!\nUID: ${user.uid}';
      });

    } catch (e) {
      setState(() {
        _status = 'Error creating admin: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 2: Test Admin Status
  Future<void> testAdminStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing admin status...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _status = 'Error: No user logged in.';
        });
        return;
      }

      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      
      if (adminDoc.exists) {
        setState(() {
          _status = 'Admin status: CONFIRMED ✅\nData: ${adminDoc.data()}';
        });
      } else {
        setState(() {
          _status = 'Admin status: NOT FOUND ❌\nPlease create admin account first.';
        });
      }

    } catch (e) {
      setState(() {
        _status = 'Error testing admin status: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 3: Test Employee Registration (Create a dummy employee)
  Future<void> createTestEmployee() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating test employee...';
    });

    try {
      // Create a test employee record
      final testEmployeeId = 'test_employee_${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore.collection('employees').doc(testEmployeeId).set({
        'firebaseUid': testEmployeeId,
        'email': 'test@company.com',
        'name': 'Test Employee',
        'phone': '1234567890',
        'department': 'IT',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _status = 'Test employee created successfully!\nID: $testEmployeeId\nStatus: pending';
      });

    } catch (e) {
      setState(() {
        _status = 'Error creating test employee: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 4: List Pending Employees
  Future<void> listPendingEmployees() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading pending employees...';
    });

    try {
      final querySnapshot = await _firestore
          .collection('employees')
          .where('status', isEqualTo: 'pending')
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _status = 'No pending employees found.';
        });
      } else {
        String employeeList = 'Pending Employees:\n\n';
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          employeeList += '• ${data['name']} (${data['email']})\n';
          employeeList += '  ID: ${doc.id}\n';
          employeeList += '  Status: ${data['status']}\n\n';
        }
        
        setState(() {
          _status = employeeList;
        });
      }

    } catch (e) {
      setState(() {
        _status = 'Error loading employees: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 5: Approve Test Employee
  Future<void> approveTestEmployee() async {
    setState(() {
      _isLoading = true;
      _status = 'Looking for test employee to approve...';
    });

    try {
      final querySnapshot = await _firestore
          .collection('employees')
          .where('status', isEqualTo: 'pending')
          .where('name', isEqualTo: 'Test Employee')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _status = 'No test employee found. Create one first.';
        });
        return;
      }

      final employeeDoc = querySnapshot.docs.first;
      final employeeData = employeeDoc.data();
      final eid = 'EMP001'; // Assign first employee ID

      // Update employee record
      await _firestore.collection('employees').doc(employeeDoc.id).update({
        'status': 'approved',
        'eid': eid,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser!.uid,
      });

      // Create user profile
      await _firestore.collection('users').doc(eid).set({
        'eid': eid,
        'firebaseUid': employeeDoc.id,
        'email': employeeData['email'],
        'name': employeeData['name'],
        'phone': employeeData['phone'],
        'department': employeeData['department'],
        'status': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _status = 'Test employee approved successfully! ✅\n'
                 'Employee ID: $eid\n'
                 'User profile created in /users/$eid';
      });

    } catch (e) {
      setState(() {
        _status = 'Error approving employee: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 6: Test Security Rules
  Future<void> testSecurityRules() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing security rules...';
    });

    try {
      String testResults = 'Security Rules Test Results:\n\n';

      // Test 1: Admin can read employees
      try {
        final employeesQuery = await _firestore.collection('employees').limit(1).get();
        testResults += '✅ Admin can read employees collection\n';
      } catch (e) {
        testResults += '❌ Admin cannot read employees: $e\n';
      }

      // Test 2: Admin can read users
      try {
        final usersQuery = await _firestore.collection('users').limit(1).get();
        testResults += '✅ Admin can read users collection\n';
      } catch (e) {
        testResults += '❌ Admin cannot read users: $e\n';
      }

      // Test 3: Admin can read attendance
      try {
        final attendanceQuery = await _firestore.collection('attendance').limit(1).get();
        testResults += '✅ Admin can read attendance collection\n';
      } catch (e) {
        testResults += '❌ Admin cannot read attendance: $e\n';
      }

      setState(() {
        _status = testResults;
      });

    } catch (e) {
      setState(() {
        _status = 'Error testing security rules: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Setup & Testing'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current User Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current User:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Email: ${_auth.currentUser?.email ?? 'Not logged in'}'),
                    Text('UID: ${_auth.currentUser?.uid ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Action Buttons
            ElevatedButton(
              onPressed: _isLoading ? null : createAdminAccount,
              child: Text('1. Create Admin Account'),
            ),
            
            SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : testAdminStatus,
              child: Text('2. Test Admin Status'),
            ),
            
            SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : createTestEmployee,
              child: Text('3. Create Test Employee'),
            ),
            
            SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : listPendingEmployees,
              child: Text('4. List Pending Employees'),
            ),
            
            SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : approveTestEmployee,
              child: Text('5. Approve Test Employee'),
            ),
            
            SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : testSecurityRules,
              child: Text('6. Test Security Rules'),
            ),
            
            SizedBox(height: 20),
            
            // Status Display
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (_isLoading)
                        Center(child: CircularProgressIndicator())
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(_status),
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
    );
  }
}

// Usage: Add this to your app for testing
// Navigator.push(context, MaterialPageRoute(builder: (context) => QuickAdminSetup()));
