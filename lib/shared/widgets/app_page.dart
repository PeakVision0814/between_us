import 'package:flutter/material.dart';

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: children,
    );
  }
}
