import 'package:flutter/material.dart';
import '../theme.dart';

class AddFriendPage extends StatelessWidget {
  const AddFriendPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      appBar: AppBar(title: const Text('Add Friend')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(decoration: kTextFieldDecoration.copyWith(labelText: 'Search People')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Send Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}