import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Displays the user's list of favourite videos and books.
///
/// This page listens to a `favorites` subcollection within the current user's
/// document. Each favourite item stores a `contentId` and `type` (video or book).
/// The page then fetches the relevant content documents from Firestore and
/// displays them grouped by type. If the user is not signed in, a simple
/// message is shown instructing them to sign in.
class MyListPage extends StatefulWidget {
  const MyListPage({super.key});

  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('قائمتي'),
        ),
        body: const Center(
          child: Text('يرجى تسجيل الدخول لاستخدام قائمة المفضلة'),
        ),
      );
    }
    final favsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favorites')
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمتي'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: favsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final favs = snapshot.data?.docs ?? [];
          if (favs.isEmpty) {
            return const Center(child: Text('لا توجد عناصر في قائمتك'));
          }
          // Separate favourites by type.
          final videoFavs = favs
              .where((doc) => (doc.data() as Map<String, dynamic>)['type'] ==
                  'video')
              .toList();
          final bookFavs = favs
              .where((doc) => (doc.data() as Map<String, dynamic>)['type'] ==
                  'book')
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (videoFavs.isNotEmpty) ...[
                Text(
                  'قوائم الفيديو',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...videoFavs.map((favDoc) {
                  final data = favDoc.data() as Map<String, dynamic>;
                  final videoId = data['contentId'] as String;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('videos')
                        .doc(videoId)
                        .get(),
                    builder: (context, videoSnapshot) {
                      if (videoSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const ListTile(
                          title: Text('...'),
                        );
                      }
                      if (!videoSnapshot.hasData || !videoSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      final videoData = videoSnapshot.data!.data()
                          as Map<String, dynamic>;
                      final title = videoData['title'] as String? ?? '';
                      return ListTile(
                        leading: const Icon(Icons.play_circle_fill),
                        title: Text(title),
                        onTap: () {
                          // TODO: navigate to video player page.
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await favDoc.reference.delete();
                          },
                        ),
                      );
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],
              if (bookFavs.isNotEmpty) ...[
                Text(
                  'قوائم الكتب',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...bookFavs.map((favDoc) {
                  final data = favDoc.data() as Map<String, dynamic>;
                  final bookId = data['contentId'] as String;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('books')
                        .doc(bookId)
                        .get(),
                    builder: (context, bookSnapshot) {
                      if (bookSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const ListTile(
                          title: Text('...'),
                        );
                      }
                      if (!bookSnapshot.hasData || !bookSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      final bookData = bookSnapshot.data!.data()
                          as Map<String, dynamic>;
                      final title = bookData['title'] as String? ?? '';
                      return ListTile(
                        leading: const Icon(Icons.book),
                        title: Text(title),
                        onTap: () {
                          // TODO: open book viewer.
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await favDoc.reference.delete();
                          },
                        ),
                      );
                    },
                  );
                }).toList(),
              ],
            ],
          );
        },
      ),
    );
  }
}