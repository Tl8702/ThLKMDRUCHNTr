import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/language_selection.dart';
import 'pages/home_page_updated.dart';
import 'firebase_options.dart';

/// Entry point of the application using the updated home page.
///
/// This file mirrors the original `main.dart` but navigates to
/// [HomePageUpdated] after the language selection. It ensures that
/// Firebase and SharedPreferences are initialised before building the
/// widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final selectedLang = prefs.getString('selected_language');
  runApp(MyApp(isFirstRun: selectedLang == null));
}

/// Root widget for the admin application. Uses [HomePageUpdated] as the
/// landing screen once a language has been selected.
class MyApp extends StatelessWidget {
  final bool isFirstRun;
  const MyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: isFirstRun
          ? const LanguageSelectionPage()
          : const HomePageUpdated(),
    );
  }
}