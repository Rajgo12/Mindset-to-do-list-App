  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'api_connection.dart';

  class ProfilePageApi {
    /// Fetch accepted friends list
    static Future<List<dynamic>> fetchFriends(int userId) async {
      final url = Uri.parse('${ApiConnection.hostConnectFriends}/get_friends.php?user_id=$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw Exception('Failed to parse friends data');
        }
      } else {
        throw Exception('Failed to load friends (Status ${response.statusCode})');
      }
    }

    /// Fetch pending friend requests
    static Future<List<dynamic>> fetchFriendRequests(int userId) async {
      final url = Uri.parse('${ApiConnection.hostConnectFriends}/manage_friend_request.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'action': 'get_requests',
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return data['requests'];
          } else {
            throw Exception(data['message'] ?? 'Unknown error retrieving requests');
          }
        } catch (e) {
          throw Exception('Failed to parse friend requests');
        }
      } else {
        throw Exception('Failed to load friend requests (Status ${response.statusCode})');
      }
    }

    /// Delete a friend (both directions)
    static Future<bool> deleteFriend(int userId, int friendId) async {
      final url = Uri.parse('${ApiConnection.hostConnectFriends}/delete_friend.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'friend_id': friendId,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['success'] == true;
        } catch (e) {
          throw Exception('Failed to parse delete response');
        }
      } else {
        throw Exception('Failed to delete friend (Status ${response.statusCode})');
      }
    }

    /// Send a friend request (alias of addFriend)
    static Future<bool> sendFriendRequest(int userId, int friendId) async {
      return addFriend(userId, friendId);
    }

    /// Add a friend (send friend request)
    static Future<bool> addFriend(int userId, int friendId) async {
      final url = Uri.parse('${ApiConnection.hostConnectFriends}/add_friend.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'friend_id': friendId,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['success'] == true;
        } catch (e) {
          throw Exception('Failed to parse add friend response');
        }
      } else {
        throw Exception('Failed to add friend (Status ${response.statusCode})');
      }
    }

    /// Accept or reject a friend request
    static Future<bool> manageFriendRequest({
      required int userId,
      required int requesterId,
      required String action, // 'accept' or 'reject'
    }) async {
      final url = Uri.parse('${ApiConnection.hostConnectFriends}/manage_friend_request.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'requester_id': requesterId,
          'action': action,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['success'] == true;
        } catch (e) {
          throw Exception('Failed to parse friend request response');
        }
      } else {
        throw Exception('Failed to manage friend request (Status ${response.statusCode})');
      }
    }

    /// Search for users
    static Future<List<dynamic>> searchUsers(String query) async {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final url = Uri.parse('${ApiConnection.hostConnectFriends}/search_users.php?query=$encodedQuery');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw Exception('Failed to parse search results');
        }
      } else {
        throw Exception('Failed to search users (Status ${response.statusCode})');
      }
    }
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
    return {'success': false, 'message': 'already have a collaboration with this user'};
  }
}

  }
