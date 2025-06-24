import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/main_nav_scaffold.dart';

class GroceryPage extends StatelessWidget {
  const GroceryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MainNavScaffold(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: kAppBackground,
        appBar: AppBar(
          title: const Text('Grocery'),
        ),
        body: const Center(child: Text('Grocery Tasks Here')),
      ),
    );
  }
}