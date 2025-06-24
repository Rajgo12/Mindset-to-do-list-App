import 'package:flutter/material.dart';
import '../theme.dart';

class CustomPopupBox extends StatelessWidget {
  final String title;
  final List<String> items;
  const CustomPopupBox({super.key, required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kAppBackground,
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map((item) => Card(
                  color: Colors.grey[100],
                  child: ListTile(
                    title: Text(item),
                    onTap: () => Navigator.pop(context),
                  ),
                ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}