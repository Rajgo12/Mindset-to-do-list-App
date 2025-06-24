import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/main_nav_scaffold.dart';
import '../api/collab_api.dart';
import 'collab_task_items_page.dart';

class CollabPage extends StatefulWidget {
  final int userId;

  const CollabPage({super.key, required this.userId});

  @override
  State<CollabPage> createState() => _CollabPageState();
}

class _CollabPageState extends State<CollabPage> {
  List<Map<String, dynamic>> _acceptedCollabs = [];
  List<Map<String, dynamic>> _pendingCollabs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollaborations();
  }

  Future<void> _loadCollaborations() async {
  setState(() {
    _isLoading = true;
  });

  final accepted = await CollabApi.getAcceptedCollaborations(widget.userId);
  final pending = await CollabApi.getPendingCollaborations(widget.userId);

  // Group accepted collaborations by task_id (as before)
  final Map<int, Map<String, dynamic>> grouped = {};
  for (final collab in accepted) {
    final taskId = collab['task_id'];
    if (taskId == null) continue;
    if (!grouped.containsKey(taskId)) {
      grouped[taskId] = {
        ...collab,
        'collaborators': <String>{},
      };
    }
    final userId = widget.userId;
    if (collab['collaborator_id'] != userId) {
      grouped[taskId]?['collaborators'].add(collab['collaborator_name']);
    }
    if (collab['requested_id'] != userId) {
      grouped[taskId]?['collaborators'].add(collab['requested_name']);
    }
  }
  final groupedAccepted = grouped.values.map((e) {
    return {
      ...e,
      'collaborators': (e['collaborators'] as Set<String>).toList(),
    };
  }).toList();

  // Group pending collaborations by (task_title + requested_name)
  final Map<String, Map<String, dynamic>> pendingGrouped = {};
  for (final collab in pending) {
    final key = '${collab['task_title']}|${collab['requested_name']}';
    if (!pendingGrouped.containsKey(key)) {
      pendingGrouped[key] = {
        ...collab,
        'task_item_titles': <String>[],
      };
    }
    if (collab['task_item_title'] != null) {
      (pendingGrouped[key]!['task_item_titles'] as List<String>).add(collab['task_item_title']);
    }
  }
  final groupedPending = pendingGrouped.values.toList();

  setState(() {
    _acceptedCollabs = groupedAccepted;
    _pendingCollabs = groupedPending;
    _isLoading = false;
  });
}

    Widget _buildTaskList(String title, List<Map<String, dynamic>> tasks, {bool isPending = false}) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                isPending ? Icons.hourglass_empty : Icons.group_off,
                size: 60,
                color: isPending ? Colors.orange.shade300 : Colors.blueGrey.shade200,
              ),
              const SizedBox(height: 16),
              Text(
                isPending
                    ? "No pending collaboration requests."
                    : "No Collaborations yet.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final project = tasks[index];
            final taskId = project['task_id'];

            // For accepted collaborations, show "Collaborated by" and "Collaboration with"
            Widget? subtitleWidget;
            if (!isPending && taskId != null) {
              final collaboratedBy = project['collaborated_by'] ?? '';
              final collaborationWith = (project['collaboration_with'] is List)
                  ? (project['collaboration_with'] as List)
                      .map((u) => u['username'])
                      .join(', ')
                  : '';
              subtitleWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (collaboratedBy.isNotEmpty)
                    Text('Collaborated by: $collaboratedBy', style: const TextStyle(fontSize: 14)),
                  if (collaborationWith.isNotEmpty)
                    Text('Collaboration with: $collaborationWith', style: const TextStyle(fontSize: 14)),
                ],
              );
            }

            return Card(
              color: const Color.fromARGB(255, 204, 227, 255),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.group, color: Colors.blue),
                title: Text(project['task_title'] ?? ''),
                subtitle: isPending
                    ? (() {
                        String direction;
                        String name;
                        if (project['collaborator_id'] == widget.userId) {
                          direction = 'To';
                          name = project['requested_name'] ?? 'Unknown';
                        } else if (project['requested_id'] == widget.userId) {
                          direction = 'From';
                          name = project['collaborator_name'] ?? 'Unknown';
                        } else {
                          direction = '';
                          name = '';
                        }
                        String taskItems = (project['task_item_titles'] as List<String>?)?.join(', ') ?? 'N/A';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$direction: $name', style: const TextStyle(fontSize: 14)),
                            Text('task item: $taskItems', style: const TextStyle(fontSize: 14)),
                          ],
                        );
                      })()
                    : (subtitleWidget ?? const Text('No collaborators')),
                trailing: isPending && project['requested_id'] == widget.userId
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await CollabApi.respondToCollaboration(project['id'], 'accepted');
                              await _loadCollaborations();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await CollabApi.respondToCollaboration(project['id'], 'rejected');
                              await _loadCollaborations();
                            },
                          ),
                        ],
                      )
                    : const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: !isPending && taskId != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CollabTaskItemsPage(
                              taskId: taskId,
                              taskTitle: project['task_title'] ?? '',
                              userId: widget.userId,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return MainNavScaffold(
      selectedIndex: 2,
      child: Scaffold(
        backgroundColor: kAppBackground,
        appBar: AppBar(
          backgroundColor: Color(0xFF0256BF), // Change this to your desired color
          foregroundColor: Colors.white,
          title: const Text('Collaborations'),
          automaticallyImplyLeading: false, // Removes the back button
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadCollaborations,
                child: ListView(
                  padding: const EdgeInsets.only(top: 8),
                  children: [
                    _buildTaskList('Accepted Collaborations', _acceptedCollabs),
                    const SizedBox(height: 16),
                    _buildTaskList('Pending Collaboration Requests', _pendingCollabs, isPending: true),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
        // floatingActionButton: CustomAddButton(
        //   onPressed: _showAddCollabDialog,
        // ),
      ),
    );
  }

}