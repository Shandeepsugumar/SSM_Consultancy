// Employee Registration and Approval Workflow Implementation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Employee Registration (called after Firebase Auth registration)
  static Future<void> registerEmployee({
    required String email,
    required String name,
    required String phone,
    required String department,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('employees').doc(user.uid).set({
      'firebaseUid': user.uid,
      'email': email,
      'name': name,
      'phone': phone,
      'department': department,
      'status': 'pending', // Waiting for admin approval
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('Employee registration submitted for approval');
  }

  // 2. Check Employee Status
  static Future<Map<String, dynamic>?> getEmployeeStatus() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('employees').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
  }

  // 3. Admin: Get Pending Employees
  static Future<List<Map<String, dynamic>>> getPendingEmployees() async {
    final querySnapshot = await _firestore
        .collection('employees')
        .where('status', isEqualTo: 'pending')
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  // 4. Admin: Approve Employee and Assign Eid
  static Future<void> approveEmployee({
    required String firebaseUid,
    required String eid,
  }) async {
    final adminUser = _auth.currentUser;
    if (adminUser == null) throw Exception('Admin not authenticated');

    // Update employee record with approval and Eid
    await _firestore.collection('employees').doc(firebaseUid).update({
      'status': 'approved',
      'eid': eid,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': adminUser.uid,
    });

    // Get employee data for user profile creation
    final employeeDoc = await _firestore.collection('employees').doc(firebaseUid).get();
    final employeeData = employeeDoc.data()!;

    // Create user profile using Eid as document ID
    await _firestore.collection('users').doc(eid).set({
      'eid': eid,
      'firebaseUid': firebaseUid,
      'email': employeeData['email'],
      'name': employeeData['name'],
      'phone': employeeData['phone'],
      'department': employeeData['department'],
      'status': true, // Active employee
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('Employee $eid approved successfully');
  }

  // 5. Admin: Reject Employee
  static Future<void> rejectEmployee(String firebaseUid) async {
    await _firestore.collection('employees').doc(firebaseUid).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // 6. Get Employee Eid (for approved employees)
  static Future<String?> getEmployeeEid() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('employees').doc(user.uid).get();
    if (doc.exists && doc.data()?['status'] == 'approved') {
      return doc.data()?['eid'];
    }
    return null;
  }
}

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mark Attendance using Employee Eid
  static Future<void> markAttendance({
    required String eid,
    required String type, // 'checkin' or 'checkout'
    required GeoPoint location,
  }) async {
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final attendanceRef = _firestore
        .collection('attendance')
        .doc(eid)
        .collection('dates')
        .doc(dateString);

    if (type == 'checkin') {
      await attendanceRef.set({
        'eid': eid,
        'date': dateString,
        'checkIn': FieldValue.serverTimestamp(),
        'checkInLocation': location,
      }, SetOptions(merge: true));
    } else {
      await attendanceRef.update({
        'checkOut': FieldValue.serverTimestamp(),
        'checkOutLocation': location,
      });
    }
  }

  // Get Attendance History
  static Future<List<Map<String, dynamic>>> getAttendanceHistory(String eid) async {
    final querySnapshot = await _firestore
        .collection('attendance')
        .doc(eid)
        .collection('dates')
        .orderBy('date', descending: true)
        .limit(30)
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }
}

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update Live Location using Employee Eid
  static Future<void> updateLiveLocation({
    required String eid,
    required GeoPoint location,
    required double accuracy,
  }) async {
    await _firestore.collection('live_locations').doc(eid).set({
      'eid': eid,
      'location': location,
      'accuracy': accuracy,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Track Location History using Employee Eid
  static Future<void> trackLocation({
    required String eid,
    required GeoPoint location,
    required double accuracy,
  }) async {
    await _firestore.collection('location_tracking').doc().set({
      'eid': eid,
      'location': location,
      'accuracy': accuracy,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class SalaryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin: Create Salary Record
  static Future<void> createSalaryRecord({
    required String eid,
    required double basicSalary,
    required double allowances,
    required double deductions,
    required String month,
    required int year,
  }) async {
    final salaryId = '${eid}_${year}_${month}';
    
    await _firestore.collection('salary_records').doc(salaryId).set({
      'eid': eid,
      'basicSalary': basicSalary,
      'allowances': allowances,
      'deductions': deductions,
      'netSalary': basicSalary + allowances - deductions,
      'month': month,
      'year': year,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Employee: Get Own Salary Records
  static Future<List<Map<String, dynamic>>> getSalaryRecords(String eid) async {
    final querySnapshot = await _firestore
        .collection('salary_records')
        .where('eid', isEqualTo: eid)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }
}

// Usage Example in your app:

class LoginService {
  static Future<String> loginEmployee(String email, String password) async {
    // 1. Sign in with Firebase Auth
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Check employee status
    final employeeStatus = await EmployeeService.getEmployeeStatus();
    
    if (employeeStatus == null) {
      throw Exception('Employee record not found');
    }

    if (employeeStatus['status'] == 'pending') {
      throw Exception('Account pending approval');
    }

    if (employeeStatus['status'] == 'rejected') {
      throw Exception('Account has been rejected');
    }

    if (employeeStatus['status'] == 'approved') {
      return employeeStatus['eid']; // Return Eid for use in app
    }

    throw Exception('Invalid account status');
  }
}

// Example usage in your main app:
/*
void main() async {
  // Employee login
  try {
    String eid = await LoginService.loginEmployee('employee@company.com', 'password');
    print('Logged in with Eid: $eid');
    
    // Now use Eid for all operations
    await AttendanceService.markAttendance(
      eid: eid,
      type: 'checkin',
      location: GeoPoint(12.9716, 77.5946),
    );
    
    await LocationService.updateLiveLocation(
      eid: eid,
      location: GeoPoint(12.9716, 77.5946),
      accuracy: 5.0,
    );
    
  } catch (e) {
    print('Login failed: $e');
  }
}
*/
