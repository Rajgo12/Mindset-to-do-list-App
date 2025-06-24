import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_connection.dart';

class Note {
  final int id;
  final int userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    String decodedContent = '';
    try {
      decodedContent = utf8.decode(base64.decode(json['content'] ?? ''));
    } catch (_) {
      decodedContent = json['content'] ?? ''; // fallback if not encoded
    }

    return Note(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      title: json['title'] ?? '',
      content: decodedContent,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}


class NotesApi {
  /// Add a new note for the given user
  static Future<bool> addNote(int userId, String title, String content) async {
    final response = await http.post(
      Uri.parse(ApiConnection.addNote),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      return resData['success'] == true;
    } else {
      return false;
    }
  }

  /// Fetch all notes for the given user
  static Future<List<Note>> fetchNotes(int userId) async {
    final response = await http.post(
      Uri.parse(ApiConnection.getNotes),
      body: {'user_id': userId.toString()},
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      if (resData['success']) {
        List<dynamic> notesJson = resData['notes'];
        return notesJson.map((json) => Note.fromJson(json)).toList();
      }
    }
    return [];
  }

  /// Update a note
  static Future<bool> updateNote(Note note) async {
    final response = await http.post(
      Uri.parse(ApiConnection.updateNotes),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'note_id': note.id,
        'title': note.title,
        'content': note.content,
      }),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      return resData['success'] == true;
    } else {
      return false;
    }
  }
  /// Delete a note by its ID
  static Future<bool> deleteNote(int noteId) async {
    final response = await http.post(
      Uri.parse(ApiConnection.deleteNote),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'note_id': noteId}),
    );
    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      return resData['success'] == true;
    }
    return false;
  }
}

