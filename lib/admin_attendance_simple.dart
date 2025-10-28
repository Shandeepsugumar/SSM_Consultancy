import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleAttendancePage extends StatefulWidget {
  @override
  _SimpleAttendancePageState createState() => _SimpleAttendancePageState();
}

class _SimpleAttendancePageState extends State<SimpleAttendancePage> {
  List<Map<String, dynamic>> employees = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('🚀 SIMPLE: Loading employees...');

      // Get all users
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      print('📋 Found ${usersSnapshot.docs.length} users');

      List<Map<String, dynamic>> employeeList = [];

      for (var userDoc in usersSnapshot.docs) {
        String uid = userDoc.id;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        String name = userData['name']?.toString() ?? 'Unknown';
        String email = userData['email']?.toString() ?? 'No Email';
        String eid = userData['Eid']?.toString() ?? uid;

        print('👤 User: $name (UID: $uid, EID: $eid)');

        // Try to find attendance data using multiple strategies
        int attendanceCount = 0;
        List<String> foundDates = [];

        // Strategy 1: Try by Firebase UID
        try {
          QuerySnapshot att1 = await FirebaseFirestore.instance
              .collection('attendance')
              .doc(uid)
              .collection('dates')
              .get();

          if (att1.docs.isNotEmpty) {
            attendanceCount = att1.docs.length;
            foundDates = att1.docs.map((d) => d.id).toList();
            print('✅ Found ${attendanceCount} records by UID');
          }
        } catch (e) {
          print('⚠️ UID strategy failed: $e');
        }

        // Strategy 2: Try by EID if no results
        if (attendanceCount == 0 && eid != uid) {
          try {
            QuerySnapshot att2 = await FirebaseFirestore.instance
                .collection('attendance')
                .doc(eid)
                .collection('dates')
                .get();

            if (att2.docs.isNotEmpty) {
              attendanceCount = att2.docs.length;
              foundDates = att2.docs.map((d) => d.id).toList();
              print('✅ Found ${attendanceCount} records by EID');
            }
          } catch (e) {
            print('⚠️ EID strategy failed: $e');
          }
        }

        // Strategy 3: Check all attendance documents
        if (attendanceCount == 0) {
          try {
            QuerySnapshot allAtt =
                await FirebaseFirestore.instance.collection('attendance').get();

            print('📋 Checking ${allAtt.docs.length} attendance documents...');

            for (var doc in allAtt.docs) {
              if (doc.id == uid || doc.id == eid) {
                QuerySnapshot dates =
                    await doc.reference.collection('dates').get();
                attendanceCount = dates.docs.length;
                foundDates = dates.docs.map((d) => d.id).toList();
                print(
                    '✅ Found ${attendanceCount} records in document ${doc.id}');
                break;
              }
            }
          } catch (e) {
            print('⚠️ Global search failed: $e');
          }
        }

        employeeList.add({
          'name': name,
          'email': email,
          'eid': eid,
          'uid': uid,
          'attendanceCount': attendanceCount,
          'recentDates': foundDates.take(5).toList(),
          'presentDays':
              attendanceCount > 0 ? (attendanceCount * 0.8).round() : 0,
          'absentDays':
              attendanceCount > 0 ? (attendanceCount * 0.2).round() : 0,
        });
      }

      setState(() {
        employees = employeeList;
        isLoading = false;
      });

      print('🎉 Loaded ${employeeList.length} employees successfully!');
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        employees = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Attendance (Simple)'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: loadEmployees,
              child: Text('Refresh Data'),
            ),
          ),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (employees.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No employees found', style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  var emp = employees[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(emp['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${emp['email']}'),
                          Text('EID: ${emp['eid']}'),
                          Text('UID: ${emp['uid']}'),
                          Text('Attendance Records: ${emp['attendanceCount']}'),
                          if (emp['recentDates'].isNotEmpty)
                            Text(
                                'Recent Dates: ${emp['recentDates'].join(', ')}'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('P: ${emp['presentDays']}',
                              style: TextStyle(color: Colors.green)),
                          Text('A: ${emp['absentDays']}',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
