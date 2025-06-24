import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import 'notes_page.dart';
import 'collab_page.dart';
import 'reminder_page.dart';
import 'profile_page.dart';
import 'dynamic_task_page.dart';
import '../api/api_connection.dart';

class MainNavPage extends StatefulWidget {
  final int userId;
  final String email;
  final String username;

  const MainNavPage({
    super.key,
    required this.userId,
    required this.email,
    required this.username,
  });

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  int _selectedIndex = 0;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  late List<Widget> _pages;

    @override
    void initState() {
      super.initState();
      _pages = [
        HomePage(
          key: _homePageKey,
          userId: widget.userId,
          email: widget.email,
          username: widget.username,
          onAddTask: _addDynamicTask,
        ),
        NotesPage(userId: widget.userId),
        CollabPage(userId: widget.userId),
        ReminderPage(userId: widget.userId), // Pass userId here
        ProfilePage(
          userId: widget.userId,
          email: widget.email,
          username: widget.username,
        ),
      ];
    }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addDynamicTask(String taskName) {
    _homePageKey.currentState?.addDynamicTask(taskName: taskName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0256BF),
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: const Color.fromARGB(255, 0, 38, 85),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Collaborations'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// HOMEPAGE IMPLEMENTATION

class HomePage extends StatefulWidget {
  final void Function(String) onAddTask;
  final int userId;
  final String email;
  final String username;

  const HomePage({
    super.key,
    required this.onAddTask,
    required this.userId,
    required this.email,
    required this.username,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<_TaskCardData> _tasks = [];
  bool _loading = true;
  String? _error;

  int get userId => widget.userId;

  @override
  void initState() {
    super.initState();
    _loadTasksFromBackend();
  }

  Future<void> _loadTasksFromBackend() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('${ApiConnection.getTask}?user_id=$userId'));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['tasks'] is List) {
          final tasksList = data['tasks'] as List<dynamic>;
          setState(() {
            _tasks = tasksList.map((taskJson) {
              final title = taskJson['title'] ?? 'Untitled';
              return _TaskCardData(
                title: title,
                icon: Icons.assignment,
                color: const Color.fromARGB(255, 204, 227, 255),
                pageBuilder: () => DynamicTaskPage(taskName: title, taskId: taskJson['id'], userId: userId),
                id: taskJson['id'],
              );
            }).toList();
          });
        } else {
          setState(() => _error = 'No tasks found.');
        }
      } else {
        setState(() => _error = 'Server returned invalid response.');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> addDynamicTask({
    required String taskName,
    String description = '',
    String? dueDate,
  }) async {
    final url = Uri.parse(ApiConnection.addTask);
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'user_id': userId,
      'title': taskName,
      'description': description,
      'due_date': (dueDate != null && dueDate.isNotEmpty) ? dueDate : null,
    });
    try {
      final response = await http.post(url, headers: headers, body: body);
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data['success']) {
          print('Task added!');
          await _loadTasksFromBackend();
        } else {
          _showSnack('Failed to add task: ${data['message']}');
        }
      } else {
        _showSnack('Failed to add task. Server Error.');
      }
    } catch (e) {
      _showSnack('Caught error: $e');
    }
  }

  Future<void> _editTask(int index) async {
    String updatedName = _tasks[index].title;
    final controller = TextEditingController(text: updatedName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAppBackground,
        title: const Text('Edit Task Name'),
        content: TextField(
          decoration: kTextFieldDecoration.copyWith(labelText: 'Task Name'),
          controller: controller,
          onChanged: (value) => updatedName = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (updatedName.trim().isNotEmpty) {
                Navigator.pop(context);
                final taskId = _tasks[index].id;
                if (taskId == null) return _showSnack('Invalid task id');

                final response = await http.post(
                  Uri.parse(ApiConnection.updateTask),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'task_id': taskId, 'title': updatedName.trim()}),
                );

                if (response.statusCode == 200) {
                  final res = jsonDecode(response.body);
                  if (res['success'] == true) {
                    await _loadTasksFromBackend();
                  } else {
                    _showSnack('Failed to update task');
                  }
                } else {
                  _showSnack('Failed to update task: Server error');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(int index) async {
    final taskId = _tasks[index].id;
    if (taskId == null) return _showSnack('Invalid task id');

    final response = await http.post(
      Uri.parse(ApiConnection.deleteTask),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'task_id': taskId}),
    );

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      if (res['success'] == true) {
        setState(() => _tasks.removeAt(index));
      } else {
        _showSnack('Failed to delete task');
      }
    } else {
      _showSnack('Failed to delete task: Server error');
    }
  }

  void _showAddTaskDialog() {
    String newTask = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAppBackground,
        title: const Text('Task'),
        content: TextField(
          decoration: kTextFieldDecoration.copyWith(labelText: 'Task Name'),
          onChanged: (value) => newTask = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (newTask.trim().isNotEmpty) {
                Navigator.pop(context);
                widget.onAddTask(newTask.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kAppBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: kAppBackground,
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      backgroundColor: kAppBackground,
      appBar: AppBar(
        backgroundColor: Color(0xFF0256BF), // Change this to your desired color
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MindSet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color.fromARGB(255, 255, 255, 255))),
                  Text('Your personal task assistant', style: TextStyle(fontSize: 13, color: Color.fromARGB(255, 255, 235, 52))),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: FloatingActionButton(
                      heroTag: 'homeAdd',
                      backgroundColor: Color(0xFFFEFCFA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onPressed: _showAddTaskDialog,
                      child: const Icon(Icons.add, color: Color.fromARGB(255, 36, 135, 255), size: 26),
                      tooltip: 'Add',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        toolbarHeight: 90,
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  color: task.color,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(task.icon, color: kPrimaryBlue),
                    ),
                    title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit') _editTask(index);
                        if (value == 'delete') _deleteTask(index);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => task.pageBuilder()));
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _TaskCardData {
  final int? id;
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function() pageBuilder;

  _TaskCardData({
    this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.pageBuilder,
  });
}