import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void testFirestoreAccess() async {
  try {
    print('🔐 Current user: ${FirebaseAuth.instance.currentUser?.uid}');

    // Test 1: Access users collection
    print('📊 Testing users collection access...');
    QuerySnapshot usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    print('✅ Users collection: Found ${usersSnapshot.docs.length} documents');

    // Test 2: Access attendance collection for specific UID
    String testUid = '0CLdJM0OI4RiU0p5b6LJtXsVUh02';
    print('📊 Testing attendance collection access for UID: $testUid...');

    DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(testUid)
        .get();
    print('✅ Attendance document exists: ${attendanceDoc.exists}');

    if (attendanceDoc.exists) {
      print('📄 Attendance data: ${attendanceDoc.data()}');
    }

    // Test 3: Access dates subcollection
    QuerySnapshot datesSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(testUid)
        .collection('dates')
        .get();
    print(
        '✅ Dates subcollection: Found ${datesSnapshot.docs.length} documents');

    for (var doc in datesSnapshot.docs) {
      print('📅 Date: ${doc.id}, Data: ${doc.data()}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
