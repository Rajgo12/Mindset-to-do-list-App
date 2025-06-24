import 'package:flutter/material.dart';
import '../theme.dart';
import '../api/notes.dart'; // For Note model and update API

class NoteDetailPage extends StatefulWidget {
  final Note note;
  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true;
    });

    final updatedNote = Note(
      id: widget.note.id,
      userId: widget.note.userId,
      title: widget.note.title, // keep original title since it's not editable
      content: _contentController.text.trim(),
      createdAt: widget.note.createdAt,
      updatedAt: DateTime.now(),
    );

    bool success = await NotesApi.updateNote(updatedNote);

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.pop(context, updatedNote);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save note')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        backgroundColor: kPrimaryBlue,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveNote,
                ),
        ],
      ),
      backgroundColor: kAppBackground,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _contentController,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Colors.black87,
            ),
            decoration: const InputDecoration(
              hintText: 'Write your note here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ),

    );
  }
}
