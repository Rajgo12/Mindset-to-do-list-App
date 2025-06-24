import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'api_connection.dart';

class TaskItemService {
  // Fetch all task items for a specific task
  static Future<List<dynamic>> getTaskItems(int taskId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConnection.getTaskItems),
        body: {"task_id": taskId.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['task_items'] ?? [];
      } else {
        throw Exception("Failed to load task items");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // Add a new task item
  static Future<bool> addTaskItem({
    required int taskId,
    required String title,
    required DateTime deadline,
  }) async {
    try {
      final deadlineStr = DateFormat("yyyy-MM-dd HH:mm:ss").format(deadline);

      final response = await http.post(
        Uri.parse(ApiConnection.addTaskItem),
        body: {
          "task_id": taskId.toString(),
          "title": title,
          "deadline": deadlineStr,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true || data['success'] == 1;
      } else {
        throw Exception("Failed to add task item");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // Update an existing task item
  static Future<bool> updateTaskItem({
    required int id,
    required String title,
    required DateTime deadline,
    required bool isCompleted,
  }) async {
    try {
      final deadlineStr = DateFormat("yyyy-MM-dd HH:mm:ss").format(deadline);

      final response = await http.post(
        Uri.parse(ApiConnection.updateTaskItem),
        body: {
          "id": id.toString(),
          "title": title,
          "deadline": deadlineStr,
          "is_completed": isCompleted ? "1" : "0",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true || data['success'] == 1;
      } else {
        throw Exception("Failed to update task item");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // Delete a task item by ID
  static Future<bool> deleteTaskItem(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConnection.deleteTaskItem),
        body: {"id": id.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true || data['success'] == 1;
      } else {
        throw Exception("Failed to delete task item");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // Assign a task item to a friend (collaboration feature)
  static Future<bool> assignTaskItemToFriend({
    required int taskItemId,     // ID of the task item
    required int assignedUserId, // Friend's user ID
    required int senderId,       // Current logged-in user ID
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConnection.assignTaskItem),
        body: {
          'task_item_id': taskItemId.toString(),
          'assigned_user_id': assignedUserId.toString(),
          'sender_id': senderId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('success')) {
          final successValue = data['success'];
          return successValue == true || successValue == 1;
        } else {
          throw Exception("Response JSON does not contain 'success' key");
        }
      } else {
        throw Exception(
            "Failed to assign task item. Server responded with status code ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error assigning task item: $e");
    }
  }

  // Fetch all task items for a specific user (for collaboration dialog)
  static Future<List<Map<String, dynamic>>> getTaskItemsForUser(int userId) async {
    final url = Uri.parse('${ApiConnection.hostConnectTaskItems}/get_task_items_for_user.php?user_id=$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['items'] != null) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
    }
    return [];
  }
}