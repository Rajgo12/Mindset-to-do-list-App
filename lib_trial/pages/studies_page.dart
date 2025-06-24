import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/main_nav_scaffold.dart';

class StudiesPage extends StatelessWidget {
  const StudiesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MainNavScaffold(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: kAppBackground,
        appBar: AppBar(
          title: const Text('Studies'),
        ),
        body: const Center(child: Text('Studies Tasks Here')),
      ),
    );
  }
}