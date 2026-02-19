import 'package:flutter/material.dart';

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times'),
      ),
      body: const Center(
        child: Text(
          'Prayer Times will appear here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
