import 'package:flutter/material.dart';

/// A placeholder for the user account page. This page will show user
/// information, settings, notifications and support options. Future
/// development will tie this into Firebase Auth and Firestore.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('الإشعارات'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.support_agent),
            title: Text('الدعم والمشكلات'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('حول التطبيق'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.contact_mail),
            title: Text('تواصل معنا'),
          ),
        ],
      ),
    );
  }
}
