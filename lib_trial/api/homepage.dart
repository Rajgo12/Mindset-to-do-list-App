import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_connection.dart';

class Task {
  final int? id;
  final int userId;
  final String title;
  final bool isCompleted;

  Task({
    this.id,
    required this.userId,
    required this.title,
    this.isCompleted = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': id,
      'user_id': userId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
    };
  }
}

class HomePageService {
  static const String baseUrl = ApiConnection.hostConnectTasks;
  final int userId;

  HomePageService(this.userId);

  Future<List<Task>> getTasks() async {
    final response = await http.get(Uri.parse("$baseUrl/get_tasks.php?user_id=$userId"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['tasks'] is List) {
        return (data['tasks'] as List).map((e) => Task.fromJson(e)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<bool> addTask(Task task) async {
    final response = await http.post(
      Uri.parse("$baseUrl/add_tasks.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'user_id': task.userId,
        'title': task.title,
      }),
    );
    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      return res['success'] == true;
    }
    return false;
  }

  Future<bool> deleteTask(int taskId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/delete_tasks.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'task_id': taskId}),
    );
    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      return res['success'] == true;
    }
    return false;
  }

  Future<bool> updateTask(Task task) async {
    final response = await http.post(
      Uri.parse("$baseUrl/update_tasks.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(task.toJson()),
    );
    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      return res['success'] == true;
    }
    return false;
  }
}