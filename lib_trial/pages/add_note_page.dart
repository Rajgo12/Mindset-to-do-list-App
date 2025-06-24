import 'package:flutter/material.dart';
import '../theme.dart';

class AddNotePage extends StatelessWidget {
  const AddNotePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      appBar: AppBar(title: const Text('Add Note')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(decoration: kTextFieldDecoration.copyWith(labelText: 'Title')),
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