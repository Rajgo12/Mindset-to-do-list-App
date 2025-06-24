import 'package:flutter/material.dart';
import '../theme.dart';

class MainNavScaffold extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  const MainNavScaffold({super.key, required this.selectedIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      body: child,
    );
  }
}