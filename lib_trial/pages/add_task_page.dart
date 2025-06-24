import 'package:flutter/material.dart';
import '../theme.dart';

class AddTaskPage extends StatelessWidget {
  const AddTaskPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(decoration: kTextFieldDecoration.copyWith(labelText: 'Task Name')),
            const SizedBox(height: 16),
            TextField(decoration: kTextFieldDecoration.copyWith(labelText: 'More Details')),
            const SizedBox(height: 16),
            TextField(decoration: kTextFieldDecoration.copyWith(labelText: 'Date (optional)')),
            const SizedBox(height: 16),
            TextField(decoration: kTextFieldDecoration.copyWith(labelText: 'Collab (optional)')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}