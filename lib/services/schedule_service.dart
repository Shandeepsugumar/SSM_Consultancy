import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';
import '../session_manager.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches all schedules where the current user is assigned from schedule collection
  Future<List<ScheduleModel>> getUserSchedules() async {
    try {
      // Use SessionManager to get current user UID
      final currentUserUid = await SessionManager.getCurrentUserUid();
      if (currentUserUid == null) {
        throw Exception('User not authenticated');
      }

      print('Current User UID from Session: $currentUserUid');

      // Step 1: Get all schedule records to check permissions and find user schedules
      try {
        final allScheduleSnapshot =
            await _firestore.collection('schedule').get();
        print(
            'Total schedule records in collection: ${allScheduleSnapshot.docs.length}');

        // Filter schedule records client-side for the current user
        final userSchedules = <ScheduleModel>[];

        for (var doc in allScheduleSnapshot.docs) {
          final data = doc.data();

          // Get assignedEmployees array
          List<String> assignedEmployees = [];
          if (data['assignedEmployees'] != null) {
            assignedEmployees = List<String>.from(data['assignedEmployees']);
          }

          print(
              'Schedule ${doc.id}: assignedEmployees = $assignedEmployees, data keys: ${data.keys.toList()}');

          // Check if current user UID is in assignedEmployees
          if (assignedEmployees.contains(currentUserUid)) {
            try {
              // Use direct ScheduleModel.fromFirestore since this is schedule collection
              final schedule = ScheduleModel.fromFirestore(doc);
              userSchedules.add(schedule);
              print('Added schedule record ${doc.id} for user $currentUserUid');
              print(
                  'Schedule dates: ${schedule.startDate} to ${schedule.endDate}');
            } catch (e) {
              print('Error parsing schedule record ${doc.id}: $e');
            }
          }
        }

        print(
            'Found ${userSchedules.length} schedules for user $currentUserUid');

        // Sort by startDate
        userSchedules.sort((a, b) => a.startDate.compareTo(b.startDate));

        return userSchedules;
      } catch (e) {
        print('Error accessing schedule collection: $e');

        // Fallback: Try to query with where clause
        try {
          final querySnapshot = await _firestore
              .collection('schedule')
              .where('assignedEmployees', arrayContains: currentUserUid)
              .get();

          print(
              'Found ${querySnapshot.docs.length} schedule records using query for UID: $currentUserUid');

          final schedules = querySnapshot.docs
              .map((doc) => ScheduleModel.fromFirestore(doc))
              .toList();

          schedules.sort((a, b) => a.startDate.compareTo(b.startDate));
          return schedules;
        } catch (queryError) {
          print('Schedule query also failed: $queryError');
          return []; // Return empty list instead of throwing error
        }
      }
    } catch (e) {
      print('Error fetching user schedules from schedule collection: $e');
      return []; // Return empty list instead of throwing error
    }
  }

  /// Fetches user details for multiple user IDs
  Future<Map<String, UserModel>> getUsersDetails(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return {};

      // Firebase 'whereIn' has a limit of 10 items, so we need to chunk the requests
      Map<String, UserModel> allUsers = {};

      for (int i = 0; i < userIds.length; i += 10) {
        final chunk = userIds.skip(i).take(10).toList();

        final querySnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in querySnapshot.docs) {
          allUsers[doc.id] = UserModel.fromFirestore(doc);
        }
      }

      return allUsers;
    } catch (e) {
      print('Error fetching users details: $e');
      throw Exception('Failed to fetch user details: $e');
    }
  }

  /// Gets schedules for a specific date
  Future<List<ScheduleModel>> getSchedulesForDate(
      List<ScheduleModel> allSchedules, DateTime selectedDate) async {
    final currentUserUid = await SessionManager.getCurrentUserUid();
    if (currentUserUid == null) return [];

    return allSchedules.where((schedule) {
      // Check if current user is assigned to this schedule
      if (!schedule.assignedEmployees.contains(currentUserUid)) {
        return false;
      }

      // Check if the selected date falls within the schedule range
      return schedule.isScheduledForDate(selectedDate);
    }).toList();
  }

  /// Checks if a specific date has any scheduled work for the current user
  Future<bool> hasScheduleForDate(
      List<ScheduleModel> allSchedules, DateTime date) async {
    final currentUserUid = await SessionManager.getCurrentUserUid();
    if (currentUserUid == null) return false;

    return allSchedules.any((schedule) {
      return schedule.assignedEmployees.contains(currentUserUid) &&
          schedule.isScheduledForDate(date);
    });
  }

  /// Gets the names of assigned employees for a schedule
  List<String> getAssignedEmployeeNames(
      ScheduleModel schedule, Map<String, UserModel> usersMap) {
    return schedule.assignedEmployees
        .map((uid) => usersMap[uid]?.name ?? 'Unknown')
        .toList();
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
