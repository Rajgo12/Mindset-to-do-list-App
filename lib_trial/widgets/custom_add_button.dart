// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import '../theme.dart';

class CustomAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CustomAddButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: 56,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: kPrimaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        tooltip: 'Add',
      ),
    );
  }
}