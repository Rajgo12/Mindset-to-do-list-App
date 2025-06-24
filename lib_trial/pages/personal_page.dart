// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/main_nav_scaffold.dart';

class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});
  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  List<String> tasks = ['Task 1', 'Task 2'];
  List<String> completedTasks = ['Task 3'];

  void _deleteTask(String task, {bool completed = false}) {
    setState(() {
      if (completed) {
        completedTasks.remove(task);
      } else {
        tasks.remove(task);
      }
    });
  }

  void _completeTask(String task) {
    setState(() {
      tasks.remove(task);
      completedTasks.add(task);
    });
  }

  void _uncompleteTask(String task) {
    setState(() {
      completedTasks.remove(task);
      tasks.add(task);
    });
  }

  void _showAddTaskDialog() {
    String newTask = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAppBackground,
        title: const Text('Add Task'),
        content: TextField(
          autofocus: true,
          decoration: kTextFieldDecoration.copyWith(labelText: 'Task Name'),
          onChanged: (value) => newTask = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newTask.trim().isNotEmpty) {
                setState(() {
                  tasks.add(newTask.trim());
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainNavScaffold(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: kAppBackground,
        appBar: AppBar(
          title: const Text('Personal'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 16),
              ...tasks.map((task) => Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: IconButton(
                        icon: const Icon(Icons.radio_button_unchecked),
                        onPressed: () => _completeTask(task),
                        tooltip: 'Mark as completed',
                      ),
                      title: Text(task),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') _deleteTask(task);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
              const Text('Completed Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
              ...completedTasks.map((task) => Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: IconButton(
                        icon: const Icon(Icons.radio_button_checked, color: kAccentGreen),
                        onPressed: () => _uncompleteTask(task),
                        tooltip: 'Mark as not completed',
                      ),
                      title: Text(task),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') _deleteTask(task, completed: true);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimaryBlue,
          onPressed: _showAddTaskDialog,
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Add Task',
        ),
      ),
    );
  }
}