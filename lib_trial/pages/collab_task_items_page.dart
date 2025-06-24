import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/collab_api.dart';

class CollabTaskItemsPage extends StatefulWidget {
  final int taskId;
  final String taskTitle;
  final int userId;

  const CollabTaskItemsPage({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.userId,
  });

  @override
  State<CollabTaskItemsPage> createState() => _CollabTaskItemsPageState();
}

class _CollabTaskItemsPageState extends State<CollabTaskItemsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final items = await CollabApi.getTaskItems(widget.taskId, widget.userId);

    bool isOwner = false;
    if (items.isNotEmpty && items.first.containsKey('owner_id')) {
      isOwner = items.first['owner_id'] == widget.userId;
    }

    List<Map<String, dynamic>> filtered;
    if (isOwner) {
      filtered = items;
    } else {
      filtered = items.where((item) {
        final assignedUsers = (item['assigned_users'] as List)
            .map((u) => u['assigned_to'])
            .toList();
        return assignedUsers.contains(widget.userId);
      }).toList();
    }

    if (mounted) {
      setState(() {
        _items = filtered;
        _loading = false;
      });
    }
  }

  Future<void> _removeFromTaskItem(int taskItemId, {int? targetUserId, String? collaboratorName}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(targetUserId != null && collaboratorName != null
            ? 'Remove $collaboratorName?'
            : 'Remove from Task Item'),
        content: Text(targetUserId != null && collaboratorName != null
            ? 'Remove $collaboratorName from this task item collaboration?'
            : 'Remove yourself from this task item collaboration?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await CollabApi.deleteCollaborationByUserAndTaskItem(
        userId: widget.userId,
        taskItemId: taskItemId,
        targetUserId: targetUserId,
      );
      if (success) {
        await _loadItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(targetUserId != null && collaboratorName != null
                  ? 'Removed $collaboratorName from task item'
                  : 'Removed from task item'),
            ),
          );
          if (_items.isEmpty) {
            Navigator.pop(context);
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(targetUserId != null && collaboratorName != null
                ? 'Failed to remove $collaboratorName'
                : 'Failed to remove from task item'),
          ),
        );
      }
    }
  }

  Future<void> _showRemoveCollaboratorsDialog(int taskItemId, List assignedUsers) async {
    final removable = assignedUsers.where((u) => u['assigned_to'] != widget.userId).toList();
    if (removable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No collaborators to remove.')),
      );
      return;
    }
    final selected = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        final Map<int, bool> checked = {
          for (var u in removable) u['assigned_to'] as int: false
        };
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Remove Collaborators'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: removable.map<Widget>((u) {
                  final collaboratorName = u['assigned_to_name'] ?? u['assigned_to']?.toString() ?? 'Unassigned';
                  final userId = u['assigned_to'] as int;
                  return CheckboxListTile(
                    value: checked[userId],
                    title: Text(collaboratorName),
                    onChanged: (val) {
                      setState(() {
                        checked[userId] = val ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final selectedIds = checked.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList();
                  Navigator.pop(context, selectedIds);
                },
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null && selected.isNotEmpty) {
      for (final targetUserId in selected) {
        final collaboratorName = assignedUsers
            .firstWhere((u) => u['assigned_to'] == targetUserId)['assigned_to_name'];
        await _removeFromTaskItem(
          taskItemId,
          targetUserId: targetUserId,
          collaboratorName: collaboratorName,
        );
      }
    }
  }

  Future<void> _toggleCompletion(int idx, bool? value) async {
    if (value == null) return;
    final item = _items[idx];
    final isOwner = item['owner_id'] == widget.userId;
    if (!isOwner) return;

    final success = await CollabApi.updateCollabTaskItemCompletion(
      taskItemId: item['id'],
      userId: widget.userId,
      isCompleted: value,
    );
    if (success) {
      await _loadItems();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update task item')),
      );
    }
  }

  Future<void> _toggleCollaboratorFinished(int taskItemId, int requestedId, bool isFinished) async {
    final collabApi = CollabApi();
    final ok = await collabApi.updateCollabIsFinished(
      taskItemId: taskItemId,
      requestedId: requestedId,
      isFinished: isFinished,
      userId: widget.userId,
    );
    if (ok) {
      await _loadItems();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update collaborator status')),
      );
    }
  }

  String? _formatDeadline(String? deadline) {
    if (deadline == null || deadline.isEmpty) return null;
    try {
      final dt = DateTime.parse(deadline);
      return DateFormat('MMM d, yyyy – h:mm a').format(dt);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0256BF),
        foregroundColor: Colors.white,
        title: Text(widget.taskTitle),
        actions: [],
      ),
      backgroundColor: const Color(0xFFFEFCFA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadItems,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No assigned task items found.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, idx) {
                        final item = _items[idx];
                        final isCompleted = item['is_completed'] == 1;
                        final deadlineStr = _formatDeadline(item['deadline']);
                        final assignedUsers = item['assigned_users'] as List;
                        final isOwner = item['owner_id'] == widget.userId;

                        final allCollaboratorsChecked = assignedUsers.isNotEmpty &&
                            assignedUsers.every((u) => u['is_finished'] == 1);

                        // Wrap the card in IgnorePointer if completed
                        Widget card = Card(
                          elevation: 2,
                          color: const Color.fromARGB(255, 204, 227, 255),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: isCompleted ? Colors.green : Colors.grey,
                                        size: 32,
                                      ),
                                      tooltip: isCompleted
                                          ? 'Task finished'
                                          : 'Waiting for all collaborators',
                                      onPressed: null, // Not interactable
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          item['title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isCompleted ? Colors.grey : Colors.black,
                                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: deadlineStr != null
                                            ? Row(
                                                children: [
                                                  const Icon(Icons.calendar_today,
                                                      size: 16, color: Color.fromARGB(255, 16, 48, 65)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    deadlineStr,
                                                    style: TextStyle(
                                                      color: isCompleted ? Colors.grey : Colors.blueGrey,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : null,
                                      ),
                                    ),
                                    if (isOwner)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.red),
                                        tooltip: 'Remove collaborators',
                                        onSelected: (value) async {
                                          if (value == 'remove_collaborators') {
                                            await _showRemoveCollaboratorsDialog(item['id'], assignedUsers);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'remove_collaborators',
                                            child: Row(
                                              children: [
                                                Icon(Icons.person_remove, color: Color.fromARGB(255, 56, 55, 55), size: 20),
                                                SizedBox(width: 8),
                                                Text('Remove collaborators'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                if (assignedUsers.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.people, size: 18, color: Colors.blue),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Collaborators:',
                                              style: TextStyle(fontSize: 14, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                        ...assignedUsers.map<Widget>((u) {
                                          final collaboratorName = u['assigned_to_name'] ?? u['assigned_to']?.toString() ?? 'Unassigned';
                                          final requestedId = u['assigned_to'];
                                          final isFinished = u['is_finished'] == 1;
                                          final isCurrentUser = widget.userId == requestedId;

                                          return Row(
                                            children: [
                                              Checkbox(
                                                value: isFinished,
                                                onChanged: isCompleted
                                                    ? null
                                                    : (isOwner || isCurrentUser)
                                                        ? (val) async {
                                                            if (isOwner || (isCurrentUser && val == true)) {
                                                              await _toggleCollaboratorFinished(item['id'], requestedId, val ?? false);
                                                            }
                                                          }
                                                        : null,
                                              ),
                                              Text(collaboratorName),
                                              if (isCurrentUser && !isFinished)
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 4.0),
                                                  child: Text(
                                                    "(You)",
                                                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                                                  ),
                                                ),
                                            ],
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                if (isOwner &&
                                    assignedUsers.isNotEmpty &&
                                    allCollaboratorsChecked &&
                                    !isCompleted)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.flag),
                                      label: const Text('Finish'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(120, 40),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await _toggleCompletion(idx, true);
                                      },
                                    ),
                                  ),
                                if (isCompleted)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.verified, color: Colors.green, size: 20),
                                        SizedBox(width: 6),
                                        Text(
                                          "Task Finished",
                                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );

                        // Make the whole card uninteractable if completed
                        if (isCompleted) {
                          card = IgnorePointer(
                            ignoring: true,
                            child: Opacity(
                              opacity: 0.7,
                              child: card,
                            ),
                          );
                        }

                        return card;
                      },
                    ),
            ),
    );
  }
}