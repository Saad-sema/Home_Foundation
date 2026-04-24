import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Distribution',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
