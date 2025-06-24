import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_connection.dart';  // your ApiConnection class path

class Reminder {
  final int id;
  final String title;
  final String reminderTime;
  final int is_completed;
  final bool isCollab;
  final int? ownerId;

  Reminder({
    required this.id,
    required this.title,
    required this.reminderTime,
    required this.is_completed,
    this.isCollab = false,
    this.ownerId,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      reminderTime: json['reminder_time'] ?? '',
      is_completed: int.parse(json['is_completed'].toString()),
      isCollab: json['is_collab'] == true || json['is_collab'] == 1,
      ownerId: json['owner_id'] != null ? int.tryParse(json['owner_id'].toString()) : null,
    );
  }
}

class ReminderApi {
  static Future<List<Reminder>> fetchReminders(int userId) async {
    final uri = Uri.parse('${ApiConnection.getReminders}?user_id=$userId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final remindersJson = data['reminders'] as List;
        return remindersJson.map((json) => Reminder.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load reminders');
      }
    } else {
      throw Exception('Failed to load reminders');
    }
  }

  static Future<List<Reminder>> fetchCollabReminders(int userId) async {
    // Corrected endpoint: no extra slash, use hostConnectReminder
    final uri = Uri.parse('${ApiConnection.hostConnectReminder}/fetch_collab_reminders.php?user_id=$userId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final remindersJson = data['reminders'] as List;
        return remindersJson.map((json) => Reminder.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load collaborated reminders');
      }
    } else {
      throw Exception('Failed to load collaborated reminders');
    }
  }

  // Add a reminder for a user
  static Future<bool> addReminder({
    required int userId,
    required String title,
    required String reminderTime,
  }) async {
    final uri = Uri.parse(ApiConnection.addReminder);

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        'reminder_time': reminderTime,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      return false;
    }
  }
}