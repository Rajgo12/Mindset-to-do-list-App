import 'package:flutter/material.dart';
import '../api/notes.dart'; // ← Make sure this path is correct

import '../theme.dart';
import '../widgets/NoteDetailPage.dart';
import '../widgets/main_nav_scaffold.dart';
import '../widgets/custom_add_button.dart';

class NotesPage extends StatefulWidget {
  final int userId;
  const NotesPage({super.key, required this.userId});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await NotesApi.fetchNotes(widget.userId);
    setState(() {
      _notes = notes;
      _applySearchFilter();
    });
  }

  Future<void> _addNote(String title, String content) async {
    bool success = await NotesApi.addNote(widget.userId, title, content);
    if (success) {
      _loadNotes(); // Refresh notes list
    }
  }

  Future<void> _deleteNote(int noteId) async {
    final success = await NotesApi.deleteNote(noteId);
    if (success) {
      _loadNotes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete note')),
      );
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredNotes = List.from(_notes);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredNotes = _notes.where((note) {
        final titleLower = note.title.toLowerCase();
        final contentLower = note.content.toLowerCase();
        return titleLower.contains(query) || contentLower.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applySearchFilter();
    });
  }

  void _showAddNoteDialog() {
    String noteTitle = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAppBackground,
        title: const Text('Add Note'),
        content: TextField(
          decoration: kTextFieldDecoration.copyWith(labelText: 'Title'),
          onChanged: (value) => noteTitle = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteTitle.trim().isNotEmpty) {
                _addNote(noteTitle.trim(), ''); // Pass empty string as content
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showNoteDetail(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailPage(note: note),
      ),
    );
    _loadNotes(); // Refresh when returning from NoteDetailPage
  }

  @override
  Widget build(BuildContext context) {
    return MainNavScaffold(
      selectedIndex: 1,
      child: Scaffold(
        backgroundColor: kAppBackground,
        appBar: AppBar(
          backgroundColor: Color(0xFF0256BF), // Change this to your desired color
          foregroundColor: Colors.white,
          title: const Text('Notes'),
          automaticallyImplyLeading: false, // <-- Back button removed here
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _filteredNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sticky_note_2, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No notes yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first note!',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = _filteredNotes[index];
                        return Card(
                          elevation: 2,
                          color: const Color.fromARGB(255, 204, 227, 255),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.sticky_note_2, color: Color.fromARGB(255, 255, 255, 255)),
                            title: Text(note.title),
                            subtitle: Text(note.content.split('\n').first),
                            trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'rename') {
                                String newTitle = note.title;
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Rename Note'),
                                    content: TextField(
                                      autofocus: true,
                                      decoration: const InputDecoration(labelText: 'New title'),
                                      controller: TextEditingController(text: note.title),
                                      onChanged: (val) => newTitle = val,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context, newTitle.trim());
                                        },
                                        child: const Text('Rename'),
                                      ),
                                    ],
                                  ),
                                );
                                if (result != null && result.isNotEmpty && result != note.title) {
                                  final updatedNote = Note(
                                    id: note.id,
                                    userId: note.userId,
                                    title: result,
                                    content: note.content,
                                    createdAt: note.createdAt,
                                    updatedAt: DateTime.now(),
                                  );
                                  final success = await NotesApi.updateNote(updatedNote);
                                  if (success) {
                                    _loadNotes();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to rename note')),
                                    );
                                  }
                                }
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Note'),
                                    content: const Text('Are you sure you want to delete this note?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  _deleteNote(note.id);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Text('Rename'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                            onTap: () => _showNoteDetail(note),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
        floatingActionButton: CustomAddButton(
          onPressed: _showAddNoteDialog,
        ),
      ),
    );
  }
}