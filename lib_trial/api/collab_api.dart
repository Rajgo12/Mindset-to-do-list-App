import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_connection.dart';

class CollabApi {
  Future<bool> updateCollabIsFinished({
  required int taskItemId,
  required int requestedId,
  required bool isFinished,
  required int userId,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConnection.hostConnectCollab}/update_collab_is_finished.php'),
      body: {
        'task_item_id': taskItemId.toString(),
        'requested_id': requestedId.toString(),
        'is_finished': isFinished ? '1' : '0',
        'user_id': userId.toString(),
      },
    );
    final data = json.decode(response.body);
    return data['success'] == true;
  } catch (e) {
    return false;
  }
}



  /// Get accepted collaborations for a user
  static Future<List<Map<String, dynamic>>> getAcceptedCollaborations(int userId) async {
    try {
      final url = Uri.parse('${ApiConnection.hostConnectCollab}/get_collaborations.php?user_id=$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['accepted_collaborations'] != null) {
          return List<Map<String, dynamic>>.from(data['accepted_collaborations']);
        }
      }
      return [];
    } catch (e) {
      print('Error in getAcceptedCollaborations: $e');
      return [];
    }
  }

  /// Get pending collaboration requests for a user
  static Future<List<Map<String, dynamic>>> getPendingCollaborations(int userId) async {
    try {
      final url = Uri.parse('${ApiConnection.hostConnectCollab}/get_collaborations.php?user_id=$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['pending_collaborations'] != null) {
          return List<Map<String, dynamic>>.from(data['pending_collaborations']);
        }
      }
      return [];
    } catch (e) {
      print('Error in getPendingCollaborations: $e');
      return [];
    }
  }

  /// Send collaboration request (updated to match backend)
  static Future<Map<String, dynamic>> sendCollaborationRequest({
    required int taskItemId,
    required List<int> friendIds,
    required int ownerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConnection.hostConnectCollab}/send_collaboration_request.php'),
        body: {
          'task_item_id': taskItemId.toString(),
          'friend_ids': jsonEncode(friendIds),
          'owner_id': ownerId.toString(),
        },
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error sending collaboration request: $e');
      return {'success': false, 'message': 'Error sending collaboration request'};
    }
  }

  static Future<bool> respondToCollaboration(int collabId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConnection.hostConnectCollab}/respond_collaboration.php'),
        body: {
          'collaboration_id': collabId.toString(),
          'status': status,
        },
      );
      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get task items for a task and user
  static Future<List<Map<String, dynamic>>> getTaskItems(
      int taskId, int userId, {String status = 'accepted'}) async {
    try {
      final url = Uri.parse(
        '${ApiConnection.hostConnectCollab}/get_task_items.php?task_id=$taskId&user_id=$userId&status=$status',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['items'] != null) {
          return List<Map<String, dynamic>>.from(data['items']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateCollabTaskItemCompletion({
    required int taskItemId,
    required int userId,
    required bool isCompleted,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConnection.hostConnectCollab}/update_collab_task_item.php'),
        body: {
          'id': taskItemId.toString(),
          'user_id': userId.toString(),
          'is_completed': isCompleted ? '1' : '0',
        },
      );
      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> getTaskCollaborators(int taskId) async {
    try {
      final url = Uri.parse('${ApiConnection.hostConnectCollab}/get_task_collaborators.php?task_id=$taskId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['collaborators'] is List) {
          // Ensure all items are strings
          return List<String>.from(data['collaborators'].map((e) => e.toString()));
        }
      }
      return [];
    } catch (e) {
      print('Error in getTaskCollaborators: $e');
      return [];
    }
  }

  static Future<bool> deleteCollaborationByUserAndTaskItem({
  required int userId,
  required int taskItemId,
  int? targetUserId, // NEW
}) async {
  final body = {
    'user_id': userId.toString(),
    'task_item_id': taskItemId.toString(),
  };
  if (targetUserId != null) {
    body['target_user_id'] = targetUserId.toString();
  }
  final response = await http.post(
    Uri.parse('${ApiConnection.hostConnectCollab}/delete_collaboration_by_user_and_task_item.php'),
    body: body,
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }
  return false;
}

  static Future deleteCollaborationByUserAndTask({required int userId, required int taskId}) async {}

  static Future getTaskItemsRaw(int taskId, int userId) async {}
}
// Top-level function (not static)
Future<Map<String, dynamic>> getTaskItemsRaw(
    int taskId, int userId, {String status = 'accepted'}) async {
  try {
    final url = Uri.parse(
      '${ApiConnection.hostConnectCollab}/get_task_items.php?task_id=$taskId&user_id=$userId&status=$status',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      }
    }
    return {};
  } catch (e) {
    return {};
  }
}

// Top-level function (not static)

