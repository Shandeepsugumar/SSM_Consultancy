import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonePage extends StatelessWidget {
  const DonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('✅ Done Schedules'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schedule')
            .where('status', isEqualTo: 'done')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No completed schedules.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final assignedUids = List<String>.from(data['assignedEmployees'] ?? []);

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: assignedUids)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final userDocs = userSnapshot.data?.docs ?? [];
                  final assignedNames = userDocs.map((user) => user['name'] ?? '').join(', ');

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📍 Branch: ${data['branchName']}', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('📅 ${data['startDate']} to ${data['endDate']}'),
                          Text('🕒 ${data['startTime']} - ${data['endTime']}'),
                          Text('👥 Workers: ${data['numberOfWorkers']}'),
                          Text('⏱ Hours: ${data['totalHours']}'),
                          Text('👷 Assigned Employees: $assignedNames'),
                          SizedBox(height: 6),
                          Text('🟢 Status: ${data['status']}',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
