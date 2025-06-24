// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/main_nav_scaffold.dart';
import '../api/taskitems.dart';
import '../api/profilepage.dart';

class DynamicTaskPage extends StatefulWidget {
  final String taskName;
  final int taskId;
  final int userId;  // Add this!

  const DynamicTaskPage({
    super.key,
    required this.taskName,
    required this.taskId,
    required this.userId, // Require it here too
  });

  @override
  State<DynamicTaskPage> createState() => _DynamicTaskPageState();
}

class _DynamicTaskPageState extends State<DynamicTaskPage> {
  List<Map<String, dynamic>> taskItems = [];
  bool isLoading = false;
  bool isActionLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTaskItems();
  }

  Future<void> fetchTaskItems() async {
  if (!mounted) return;
  setState(() => isLoading = true);
  try {
    final items = await TaskItemService.getTaskItems(widget.taskId);
    if (!mounted) return;

    setState(() {
      taskItems = items.map<Map<String, dynamic>>((item) {
        return {...item, 'is_completed': item['is_completed'].toString()};
      }).toList();

      // Sort by deadline ascending (earliest first)
      taskItems.sort((a, b) {
        final aDeadline = a['deadline'];
        final bDeadline = b['deadline'];
        if (aDeadline == null && bDeadline == null) return 0;
        if (aDeadline == null) return 1; // nulls go last
        if (bDeadline == null) return -1;
        return DateTime.parse(aDeadline).compareTo(DateTime.parse(bDeadline));
      });
    });
  } catch (e) {
    debugPrint('Failed to load task items: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load tasks')),
      );
    }
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

  Future<void> addNewTask(String title, DateTime deadline) async {
    if (isActionLoading) return;
    if (!mounted) return;

    setState(() => isActionLoading = true);
    try {
      bool success = await TaskItemService.addTaskItem(
        taskId: widget.taskId,
        title: title,
        deadline: deadline,
      );
      if (!mounted) return;

      if (success) {
        await fetchTaskItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add task')),
        );
      }
    } catch (e) {
      debugPrint('Error adding task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding task')),
        );
      }
    } finally {
      if (mounted) setState(() => isActionLoading = false);
    }
  }

  Future<void> toggleTask(int index) async {
    if (isActionLoading) return;
    final item = taskItems[index];
    final currentStatus = item['is_completed'] == '1';
    final newStatus = !currentStatus;

    if (!mounted) return;
    setState(() => isActionLoading = true);

    try {
      bool success = await TaskItemService.updateTaskItem(
        id: int.parse(item['id'].toString()),
        title: item['title'].toString(),
        deadline: DateTime.parse(item['deadline']),
        isCompleted: newStatus,
      );
      if (!mounted) return;

      if (success) {
        setState(() {
          taskItems[index]['is_completed'] = newStatus ? '1' : '0';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update task status')),
        );
      }
    } catch (e) {
      debugPrint('Toggle error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating task status')),
        );
      }
    } finally {
      if (mounted) setState(() => isActionLoading = false);
    }
  }

  Future<void> deleteTask(int index) async {
    if (isActionLoading) return;
    final item = taskItems[index];
    final taskId = int.parse(item['id'].toString());

    if (!mounted) return;
    setState(() => isActionLoading = true);

    try {
      bool success = await TaskItemService.deleteTaskItem(taskId);
      if (!mounted) return;

      if (success) {
        setState(() {
          taskItems.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete task')),
        );
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting task')),
        );
      }
    } finally {
      if (mounted) setState(() => isActionLoading = false);
    }
  }

  String formatDeadline(String deadline) {
    final dt = DateTime.parse(deadline);
    return DateFormat('MMM d, yyyy – h:mm a').format(dt);
  }

  Future<void> showAddTaskDialog() async {
    final itemController = TextEditingController();
    DateTime? selectedDeadline;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add New Task', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextField(
                    controller: itemController,
                    decoration: InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.task),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDeadline = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 12),
                          Text(
                            selectedDeadline != null
                                ? DateFormat('EEE, MMM d, yyyy – h:mm a').format(selectedDeadline!)
                                : 'Pick Deadline',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isActionLoading
                            ? null
                            : () {
                                if (itemController.text.trim().isNotEmpty && selectedDeadline != null) {
                                  addNewTask(itemController.text.trim(), selectedDeadline!);
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a task and deadline')),
                                  );
                                }
                              },
                        child: const Text('Add Task'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ongoingTasks = taskItems.where((t) => int.parse(t['is_completed'].toString()) == 0).toList();
    final completedTasks = taskItems.where((t) => int.parse(t['is_completed'].toString()) == 1).toList();

    return MainNavScaffold(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: kAppBackground,
        appBar: AppBar(
          backgroundColor: Color(0xFF0256BF), // Change this to your desired color
          foregroundColor: Colors.white,
          title: Text(widget.taskName),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: showCollabDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.group_add, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Collab',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: isActionLoading
            ? null
            : FloatingActionButton(
                onPressed: showAddTaskDialog,
                child: const Icon(Icons.add),
              ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (ongoingTasks.isNotEmpty) ...[
                      const Text("Ongoing Tasks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...ongoingTasks.map((task) {
                        final index = taskItems.indexWhere((e) => e['id'] == task['id']);
                        return TaskItemWidget(
                          item: task['title'],
                          deadline: formatDeadline(task['deadline']),
                          isCompleted: false,
                          onChanged: (_) => toggleTask(index),
                          onDelete: () => deleteTask(index),
                        );
                      }).toList(),
                    ],
                    if (completedTasks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text("Finished Tasks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0))),
                      const SizedBox(height: 10),
                      ...completedTasks.map((task) {
                        final index = taskItems.indexWhere((e) => e['id'] == task['id']);
                        return TaskItemWidget(
                          item: task['title'],
                          deadline: formatDeadline(task['deadline']),
                          isCompleted: true,
                          onChanged: (_) => toggleTask(index),
                          onDelete: () => deleteTask(index),
                        );
                      }).toList(),
                    ],
                    if (taskItems.isEmpty)
                      const Center(child: Text("No tasks yet. Tap + to add one.")),
                  ],
                ),
              ),
      ),
    );
  }
void showCollabDialog() {
  final Set<int> selectedFriendIds = {};
  int? selectedTaskItemId;
  bool isSending = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Collaborate on a Task Item'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedTaskItemId,
                    hint: const Text('Select Task Item'),
                    items: taskItems.map((taskItem) {
                      return DropdownMenuItem<int>(
                        value: int.parse(taskItem['id'].toString()),
                        child: Text(taskItem['title']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTaskItemId = value;
                        selectedFriendIds.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedTaskItemId != null)
                    FutureBuilder<List<dynamic>>(
                      future: ProfilePageApi.fetchFriends(widget.userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error loading friends: ${snapshot.error}');
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('No friends found.');
                        } else {
                          final friends = snapshot.data!;
                          return SizedBox(
                            height: 200,
                            child: ListView(
                              shrinkWrap: true,
                              children: friends.map<Widget>((friend) {
                                final friendId = int.parse(friend['id'].toString());
                                final friendName = friend['username'] ?? friend['email'] ?? 'Unknown';
                                final isSelected = selectedFriendIds.contains(friendId);

                                return CheckboxListTile(
                                  title: Text(friendName),
                                  value: isSelected,
                                  onChanged: (bool? checked) {
                                    setState(() {
                                      if (checked == true) {
                                        selectedFriendIds.add(friendId);
                                      } else {
                                        selectedFriendIds.remove(friendId);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        if (selectedTaskItemId == null || selectedFriendIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a task item and at least one friend')),
                          );
                          return;
                        }
                        setState(() => isSending = true);
                        final result = await ProfilePageApi.sendCollaborationRequest(
                          taskItemId: selectedTaskItemId!,
                          friendIds: selectedFriendIds.toList(),
                          ownerId: widget.userId,
                        );
                        setState(() => isSending = false);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Collaboration request sent')),
                        );
                        await fetchTaskItems();
                      },
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Request'),
              ),
            ],
          );
        },
      );
    },
  );
}


}

class TaskItemWidget extends StatelessWidget {
  final String item;
  final String deadline;
  final bool isCompleted;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onDelete;
  

  const TaskItemWidget({
    super.key,
    required this.item,
    required this.deadline,
    required this.isCompleted,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = isCompleted
        ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: const Color.fromARGB(255, 204, 227, 255),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: onChanged,
        ),
        title: Text(item, style: textStyle),
        subtitle: Text(deadline, style: textStyle),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: onDelete,
          tooltip: "Delete task",
        ),
      ),
    );
  }
}
