import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Settings Page Content',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
