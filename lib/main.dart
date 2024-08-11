import 'package:broadcast_gemini/backend/ObsAdaptorPro.dart';
import 'package:broadcast_gemini/flutter_ui/main_page.dart';
import 'package:broadcast_gemini/flutter_ui/signin_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';

Future<void> main() async {
  runApp(const MyApp());

}

bool isLoggedIn = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn) {
      return MaterialApp(
        home: MainPage(),
      );
    } else {
      return MaterialApp(
        home: LoginPage(),
      );
    }
  }
}
