import 'package:flutter/material.dart';
import 'theme.dart';
import 'main_shell.dart';

class NafasApp extends StatelessWidget {
  const NafasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nafas',
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}
