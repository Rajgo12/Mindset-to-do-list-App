  import 'package:flutter/material.dart';
  import '../theme.dart';
  import '../api/profilepage.dart';
  import 'login_page.dart'; // <-- Import your LoginPage here

  class ProfilePage extends StatefulWidget {
    final int userId;
    final String username;
    final String email;

    const ProfilePage({
      super.key,
      required this.userId,
      required this.username,
      required this.email,
    });

    @override
    State<ProfilePage> createState() => _ProfilePageState();
  }

  class _ProfilePageState extends State<ProfilePage> {
    List<Map<String, dynamic>> friends = [];
    List<Map<String, dynamic>> friendRequests = [];
    bool isLoading = true;
    bool isError = false;

    @override
    void initState() {
      super.initState();
      _loadData();
    }

    Future<void> _loadData() async {
      setState(() {
        isLoading = true;
        isError = false;
      });
      try {
        final friendList = await ProfilePageApi.fetchFriends(widget.userId);
        final requestList = await ProfilePageApi.fetchFriendRequests(widget.userId);
        setState(() {
          friends = List<Map<String, dynamic>>.from(friendList);
          friendRequests = List<Map<String, dynamic>>.from(requestList);
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
          isError = true;
        });
        debugPrint('Failed to load data: $e');
      }
    }

    Future<void> _deleteFriend(int friendId) async {
      final success = await ProfilePageApi.deleteFriend(widget.userId, friendId);
      if (success) {
        setState(() {
          friends.removeWhere((friend) => friend['id'] == friendId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete friend')),
        );
      }
    }

    Future<void> _handleFriendRequest(int requestId, String action) async {
      final request = friendRequests.firstWhere(
        (req) => req['id'] == requestId,
        orElse: () => {},
      );

      if (request.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request not found')),
        );
        return;
      }

      final requesterId = request['requester_id'] as int;

      final success = await ProfilePageApi.manageFriendRequest(
        userId: widget.userId,
        requesterId: requesterId,
        action: action,
      );

      if (success) {
        setState(() {
          friendRequests.removeWhere((req) => req['id'] == requestId);
        });

        if (action == 'accept') {
          await _loadData(); // Refresh friend list after accept
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request ${action}ed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $action friend request')),
        );
      }
    }

    void _showAddFriendDialog() {
      List<Map<String, dynamic>> searchResults = [];
      bool isSearching = false;
      bool searchError = false;
      TextEditingController searchController = TextEditingController();

      Future<void> performSearch(String query, void Function(void Function()) setState) async {
        if (query.isEmpty) {
          setState(() {
            searchResults.clear();
            isSearching = false;
            searchError = false;
          });
          return;
        }
        setState(() {
          isSearching = true;
          searchError = false;
        });

        try {
          final results = await ProfilePageApi.searchUsers(query);
          setState(() {
            searchResults = List<Map<String, dynamic>>.from(results);
            isSearching = false;
          });
        } catch (e) {
          setState(() {
            searchError = true;
            isSearching = false;
          });
        }
      }

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Friend'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by username or email',
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  performSearch(searchController.text.trim(), setState);
                                },
                              ),
                      ),
                      onSubmitted: (val) => performSearch(val.trim(), setState),
                    ),
                    if (searchError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Search failed', style: TextStyle(color: Colors.red[700])),
                      ),
                    if (searchResults.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView(
                          children: searchResults.map((user) {
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(user['username'] ?? 'Unknown'),
                              subtitle: Text(user['email'] ?? ''),
                              trailing: ElevatedButton(
                                child: const Text('Add'),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Send Friend Request'),
                                      content: Text('Send friend request to ${user['username']}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    final success = await ProfilePageApi.sendFriendRequest(
                                      widget.userId,
                                      user['id'],
                                    );
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Friend request sent to ${user['username']}')),
                                      );
                                      setState(() {
                                        searchResults.remove(user);
                                        searchController.clear();
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You are already friends')),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else if (!isSearching && searchResults.isEmpty && searchController.text.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('No results'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          });
        },
      );
    }

    void _logout() {
      // Clear any session/token here if needed
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: kAppBackground,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Color(0xFF0256BF), // Change this to your desired color
          foregroundColor: Colors.white,  // Op
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color.fromARGB(255, 204, 227, 255),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: kPrimaryBlue,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.username,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.email, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Friends Section
            const Text('Friends', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (isError)
              const Center(child: Text('Failed to load friends'))
            else if (friends.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.group_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No friends yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              )
            else
              ...friends.map((friend) {
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: const Color.fromARGB(255, 204, 227, 255),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(friend['username'] ?? 'Unknown'),
                    subtitle: Text(friend['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteFriend(friend['id']),
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),

            // Friend Requests Section
            const Text('Friend Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (isError)
              const Center(child: Text('Failed to load friend requests'))
            else if (friendRequests.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.mail_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No friend requests',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              )
            else
              ...friendRequests.map((request) {
                return Card(
                  color: const Color.fromARGB(255, 204, 227, 255),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(request['username'] ?? 'Unknown'),
                    subtitle: Text(request['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _handleFriendRequest(request['id'], 'accept'),
                          tooltip: 'Accept',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _handleFriendRequest(request['id'], 'reject'),
                          tooltip: 'Reject',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimaryBlue,
          onPressed: _showAddFriendDialog,
          tooltip: 'Add Friend',
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
      );
    }
  }