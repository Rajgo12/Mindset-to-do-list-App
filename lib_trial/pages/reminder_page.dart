import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/main_nav_scaffold.dart';
import '../api/reminders.dart';

class ReminderPage extends StatefulWidget {
  final int userId;

  const ReminderPage({super.key, required this.userId});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<Reminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
  setState(() {
    _loading = true;
  });
  try {
    final reminders = await ReminderApi.fetchReminders(widget.userId);
    final collabReminders = await ReminderApi.fetchCollabReminders(widget.userId);

    // Only show personal reminders where you are the owner (not a collab)
    final personalReminders = reminders.where((r) => !r.isCollab).toList();

    // For collab reminders, only show if you are NOT the owner
    final filteredCollabReminders = collabReminders.where((r) => r.ownerId != widget.userId).toList();

    // Deduplicate by id: if you have a personal reminder for a task, don't show the collab version
    final Map<int, Reminder> uniqueReminders = {};
    for (final r in [...personalReminders, ...filteredCollabReminders]) {
      uniqueReminders[r.id] = r;
    }

    setState(() {
      _reminders = uniqueReminders.values.toList();
      _loading = false;
    });
  } catch (e) {
    setState(() {
      _reminders = [];
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load reminders: $e')),
    );
  }
}

  DateTime? _parseReminderTime(String timeString) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(timeString);
    } catch (_) {
      return null;
    }
  }

  bool isFinished(Reminder r) => r.is_completed == 1;

  bool isDue(Reminder r) {
    if (r.is_completed == 1) return false;
    final dt = _parseReminderTime(r.reminderTime);
    return dt != null && dt.isBefore(DateTime.now());
  }

  bool isOngoing(Reminder r) {
    if (r.is_completed == 1) return false;
    final dt = _parseReminderTime(r.reminderTime);
    return dt != null && (dt.isAfter(DateTime.now()) || dt.isAtSameMomentAs(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final finished = _reminders.where(isFinished).toList();
    final dueTasks = _reminders.where(isDue).toList();
    final ongoing = _reminders.where(isOngoing).toList();

    int sortByDate(Reminder a, Reminder b) {
      final aDate = _parseReminderTime(a.reminderTime) ?? DateTime(2100);
      final bDate = _parseReminderTime(b.reminderTime) ?? DateTime(2100);
      return aDate.compareTo(bDate);
    }

    finished.sort(sortByDate);
    dueTasks.sort(sortByDate);
    ongoing.sort(sortByDate);

    Widget buildSection(String title, List<Reminder> reminders) {
      if (reminders.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...reminders.map((reminder) {
            final reminderDateTime = _parseReminderTime(reminder.reminderTime);
            final isOverdue = reminderDateTime != null && reminderDateTime.isBefore(DateTime.now()) && reminder.is_completed == 0;

            return Card(
              color: const Color.fromARGB(255, 204, 227, 255),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: reminder.isCollab
                    ? const Icon(Icons.group, color: Colors.blue)
                    : const Icon(Icons.alarm, color: Colors.blue),
                title: Row(
                  children: [
                    Text(reminder.title),
                    if (reminder.isCollab)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Collab',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: reminderDateTime != null
                    ? Text(
                        'Deadline: ${DateFormat('EEE, MMM d, yyyy – h:mm a').format(reminderDateTime)}',
                        style: TextStyle(color: isOverdue ? Colors.red : null),
                      )
                    : Text('Deadline: ${reminder.reminderTime}'),
                trailing: reminder.is_completed == 1
                    ? const Icon(Icons.check_circle, color: kAccentGreen)
                    : null,
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      );
    }

    return MainNavScaffold(
      selectedIndex: 3,
      child: Scaffold(
        backgroundColor: kAppBackground,
        appBar: AppBar(
          title: const Text('Reminders'),
          backgroundColor: Color(0xFF0256BF),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alarm_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No reminders yet',
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
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildSection('Ongoing', ongoing),
                        buildSection('Due', dueTasks),
                        buildSection('Finished', finished),
                      ],
                    ),
                  ),
      ),
    );
  }
}