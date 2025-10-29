import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';
import '../session_manager.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches all schedules where the current user is assigned from schedule collection
  /// Note: Now checks by Eid instead of UserUID since assignedEmployees contains Eids
  Future<List<ScheduleModel>> getUserSchedules() async {
    try {
      // Use SessionManager to get current user UID and data
      final currentUserUid = await SessionManager.getCurrentUserUid();
      if (currentUserUid == null) {
        throw Exception('User not authenticated');
      }

      // Get current user's data to extract Eid
      Map<String, dynamic>? currentUserData =
          await SessionManager.getCurrentUserData();
      if (currentUserData == null) {
        // If cached data is not available, fetch from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection("users").doc(currentUserUid).get();

        if (!userDoc.exists) {
          throw Exception('User data not found');
        }
        currentUserData = userDoc.data() as Map<String, dynamic>;
      }

      // Extract Eid from user data
      String? currentUserEid = currentUserData['Eid'];
      if (currentUserEid == null || currentUserEid.isEmpty) {
        print('⚠️ Warning: No Eid found for user UID: $currentUserUid');
        return []; // Return empty list if Eid is not found
      }

      print('Current User Eid from Session: $currentUserEid');

      // Step 1: Get all schedule records to check permissions and find user schedules
      try {
        print(
            '🔍 SCHEDULE SERVICE: Attempting to read all schedule documents...');
        final allScheduleSnapshot =
            await _firestore.collection('schedule').get();
        print(
            'Total schedule records in collection: ${allScheduleSnapshot.docs.length}');

        // Filter schedule records client-side for the current user
        final userSchedules = <ScheduleModel>[];

        for (var doc in allScheduleSnapshot.docs) {
          final data = doc.data();

          // Get assignedEmployees array (now contains Eids)
          List<String> assignedEmployees = [];
          if (data['assignedEmployees'] != null) {
            assignedEmployees = List<String>.from(data['assignedEmployees']);
          }

          print(
              'Schedule ${doc.id}: assignedEmployees = $assignedEmployees, data keys: ${data.keys.toList()}');

          // Check if current user Eid is in assignedEmployees
          if (assignedEmployees.contains(currentUserEid)) {
            try {
              // Use direct ScheduleModel.fromFirestore since this is schedule collection
              final schedule = ScheduleModel.fromFirestore(doc);
              userSchedules.add(schedule);
              print(
                  'Added schedule record ${doc.id} for user Eid $currentUserEid');
              print(
                  'Schedule dates: ${schedule.startDate} to ${schedule.endDate}');
            } catch (e) {
              print('Error parsing schedule record ${doc.id}: $e');
            }
          }
        }

        print(
            'Found ${userSchedules.length} schedules for user Eid $currentUserEid');

        // Sort by startDate
        userSchedules.sort((a, b) => a.startDate.compareTo(b.startDate));

        return userSchedules;
      } catch (e) {
        print(
            '⚠️ SCHEDULE SERVICE: Broad collection read failed (expected due to permissions): $e');
        print(
            '🔄 SCHEDULE SERVICE: Falling back to targeted arrayContains query...');

        // Fallback: Try to query with where clause
        try {
          final querySnapshot = await _firestore
              .collection('schedule')
              .where('assignedEmployees', arrayContains: currentUserEid)
              .get();

          print(
              '✅ SCHEDULE SERVICE: arrayContains query successful! Found ${querySnapshot.docs.length} schedule records for Eid: $currentUserEid');

          final schedules = querySnapshot.docs
              .map((doc) => ScheduleModel.fromFirestore(doc))
              .toList();

          // Log details of found schedules
          for (var schedule in schedules) {
            print(
                '📋 Found schedule: ${schedule.id} - ${schedule.branchName} (${schedule.startDate} to ${schedule.endDate})');
          }

          schedules.sort((a, b) => a.startDate.compareTo(b.startDate));
          return schedules;
        } catch (queryError) {
          print(
              '❌ SCHEDULE SERVICE: arrayContains query also failed: $queryError');
          return []; // Return empty list instead of throwing error
        }
      }
    } catch (e) {
      print('Error fetching user schedules from schedule collection: $e');
      return []; // Return empty list instead of throwing error
    }
  }

  /// Fetches user details for multiple user IDs or Eids
  /// Note: Now accepts Eids since assignedEmployees contains Eids
  Future<Map<String, UserModel>> getUsersDetails(List<String> eids) async {
    try {
      if (eids.isEmpty) return {};

      // Firebase 'whereIn' has a limit of 10 items, so we need to chunk the requests
      Map<String, UserModel> allUsers = {};

      for (int i = 0; i < eids.length; i += 10) {
        final chunk = eids.skip(i).take(10).toList();

        // Query by Eid field instead of document ID since assignedEmployees contains Eids
        final querySnapshot = await _firestore
            .collection('users')
            .where('Eid', whereIn: chunk)
            .get();

        for (var doc in querySnapshot.docs) {
          final userModel = UserModel.fromFirestore(doc);
          // Key by Eid for easy lookup
          if (userModel.eid != null) {
            allUsers[userModel.eid!] = userModel;
          }
          // Also key by document ID as fallback
          allUsers[doc.id] = userModel;
        }
      }

      return allUsers;
    } catch (e) {
      print('Error fetching users details: $e');
      throw Exception('Failed to fetch user details: $e');
    }
  }

  /// Gets schedules for a specific date
  /// Note: Now checks by Eid instead of UserUID
  Future<List<ScheduleModel>> getSchedulesForDate(
      List<ScheduleModel> allSchedules, DateTime selectedDate) async {
    final currentUserUid = await SessionManager.getCurrentUserUid();
    if (currentUserUid == null) return [];

    // Get current user's Eid
    Map<String, dynamic>? currentUserData =
        await SessionManager.getCurrentUserData();
    if (currentUserData == null) {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(currentUserUid).get();
      if (!userDoc.exists) return [];
      currentUserData = userDoc.data() as Map<String, dynamic>;
    }

    String? currentUserEid = currentUserData['Eid'];
    if (currentUserEid == null || currentUserEid.isEmpty) return [];

    return allSchedules.where((schedule) {
      // Check if current user Eid is assigned to this schedule
      if (!schedule.assignedEmployees.contains(currentUserEid)) {
        return false;
      }

      // Check if the selected date falls within the schedule range
      return schedule.isScheduledForDate(selectedDate);
    }).toList();
  }

  /// Checks if a specific date has any scheduled work for the current user
  /// Note: Now checks by Eid instead of UserUID
  Future<bool> hasScheduleForDate(
      List<ScheduleModel> allSchedules, DateTime date) async {
    final currentUserUid = await SessionManager.getCurrentUserUid();
    if (currentUserUid == null) return false;

    // Get current user's Eid
    Map<String, dynamic>? currentUserData =
        await SessionManager.getCurrentUserData();
    if (currentUserData == null) {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(currentUserUid).get();
      if (!userDoc.exists) return false;
      currentUserData = userDoc.data() as Map<String, dynamic>;
    }

    String? currentUserEid = currentUserData['Eid'];
    if (currentUserEid == null || currentUserEid.isEmpty) return false;

    return allSchedules.any((schedule) {
      return schedule.assignedEmployees.contains(currentUserEid) &&
          schedule.isScheduledForDate(date);
    });
  }

  /// Gets the names of assigned employees for a schedule
  /// Note: assignedEmployees now contains Eids, not UIDs
  List<String> getAssignedEmployeeNames(
      ScheduleModel schedule, Map<String, UserModel> usersMap) {
    return schedule.assignedEmployees.map((eid) {
      // UsersMap is now keyed by Eid, so we can directly lookup
      final user = usersMap[eid];
      return user?.name ?? 'Unknown';
    }).toList();
  }

  /// Gets all unique user IDs from all schedules
  Set<String> getAllUserIds(List<ScheduleModel> schedules) {
    Set<String> userIds = {};
    for (var schedule in schedules) {
      userIds.addAll(schedule.assignedEmployees);
    }
    return userIds;
  }

  /// Refreshes schedule data
  Future<Map<String, dynamic>> refreshScheduleData() async {
    try {
      final schedules = await getUserSchedules();
      final allUserIds = getAllUserIds(schedules);
      final usersMap = await getUsersDetails(allUserIds.toList());

      return {
        'schedules': schedules,
        'usersMap': usersMap,
      };
    } catch (e) {
      print('Error refreshing schedule data: $e');
      rethrow;
    }
  }
}
