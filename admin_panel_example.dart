// Admin Panel for Employee Management
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> pendingEmployees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPendingEmployees();
  }

  Future<void> loadPendingEmployees() async {
    try {
      final querySnapshot = await _firestore
          .collection('employees')
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        pendingEmployees = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading pending employees: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> approveEmployee(String firebaseUid, String name) async {
    // Generate unique Employee ID
    String eid = await generateEmployeeId();
    
    try {
      // Update employee record
      await _firestore.collection('employees').doc(firebaseUid).update({
        'status': 'approved',
        'eid': eid,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      // Get employee data
      final employeeDoc = await _firestore.collection('employees').doc(firebaseUid).get();
      final employeeData = employeeDoc.data()!;

      // Create user profile with Eid
      await _firestore.collection('users').doc(eid).set({
        'eid': eid,
        'firebaseUid': firebaseUid,
        'email': employeeData['email'],
        'name': employeeData['name'],
        'phone': employeeData['phone'] ?? '',
        'department': employeeData['department'] ?? '',
        'status': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name approved with Employee ID: $eid')),
      );

      // Refresh the list
      loadPendingEmployees();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving employee: $e')),
      );
    }
  }

  Future<void> rejectEmployee(String firebaseUid, String name) async {
    try {
      await _firestore.collection('employees').doc(firebaseUid).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name has been rejected')),
      );

      // Refresh the list
      loadPendingEmployees();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting employee: $e')),
      );
    }
  }

  Future<String> generateEmployeeId() async {
    // Get the last employee ID to generate next sequential ID
    final querySnapshot = await _firestore
        .collection('employees')
        .where('status', isEqualTo: 'approved')
        .orderBy('eid', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 'EMP001'; // First employee
    }

    String lastEid = querySnapshot.docs.first.data()['eid'];
    int lastNumber = int.parse(lastEid.substring(3)); // Remove 'EMP' prefix
    int nextNumber = lastNumber + 1;
    
    return 'EMP${nextNumber.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel - Employee Approvals'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pendingEmployees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'No pending approvals',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('All employees have been processed'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: pendingEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = pendingEmployees[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Text(employee['name'][0].toUpperCase()),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee['name'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        employee['email'],
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            if (employee['phone'] != null)
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(employee['phone']),
                                ],
                              ),
                            if (employee['department'] != null)
                              Row(
                                children: [
                                  Icon(Icons.business, size: 16, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(employee['department']),
                                ],
                              ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => rejectEmployee(
                                    employee['id'],
                                    employee['name'],
                                  ),
                                  icon: Icon(Icons.close, color: Colors.red),
                                  label: Text('Reject', style: TextStyle(color: Colors.red)),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => approveEmployee(
                                    employee['id'],
                                    employee['name'],
                                  ),
                                  icon: Icon(Icons.check),
                                  label: Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadPendingEmployees,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh',
      ),
    );
  }
}

// Employee List Page for Admin
class EmployeeListPage extends StatefulWidget {
  @override
  _EmployeeListPageState createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> employees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    try {
      final querySnapshot = await _firestore
          .collection('employees')
          .where('status', isEqualTo: 'approved')
          .orderBy('eid')
          .get();

      setState(() {
        employees = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading employees: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee List'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? Center(child: Text('No approved employees found'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(employee['eid']),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        title: Text(employee['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(employee['email']),
                            Text('Department: ${employee['department'] ?? 'N/A'}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(employee['eid']),
                          backgroundColor: Colors.blue[100],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// Main Admin Dashboard
class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              context,
              'Pending Approvals',
              Icons.pending_actions,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminPanelPage()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Employee List',
              Icons.people,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmployeeListPage()),
              ),
            ),
            _buildDashboardCard(
              context,
              'Attendance Reports',
              Icons.access_time,
              Colors.green,
              () {
                // Navigate to attendance reports
              },
            ),
            _buildDashboardCard(
              context,
              'Salary Management',
              Icons.attach_money,
              Colors.purple,
              () {
                // Navigate to salary management
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
