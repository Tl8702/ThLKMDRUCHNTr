import 'package:flutter/material.dart';

/// A placeholder page for the courses section. At present, it displays a
/// coming soon message. Future iterations should populate this page with
/// interactive courses.
class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدورات'),
      ),
      body: const Center(
        child: Text('قريبًا سيتم إضافة الدورات'),
      ),
    );
  }
}
