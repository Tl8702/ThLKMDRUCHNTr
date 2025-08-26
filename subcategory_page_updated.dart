import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_page.dart';

/// Displays a list of videos within a specific subcategory with navigation
/// to the video player and comments page.
///
/// This updated version of [SubcategoryPage] fetches videos filtered by
/// `subCategoryId` and language, and opens [VideoPage] when a video is
/// tapped. Admin users can add new videos via a dialog.
class SubcategoryPageUpdated extends StatefulWidget {
  final String subCategoryId;
  final String title;

  const SubcategoryPageUpdated({
    super.key,
    required this.subCategoryId,
    required this.title,
  });

  @override
  State<SubcategoryPageUpdated> createState() => _SubcategoryPageUpdatedState();
}

class _SubcategoryPageUpdatedState extends State<SubcategoryPageUpdated> {
  String? _languageCode;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _languageCode = prefs.getString('selected_language') ?? 'en';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_languageCode == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final videosStream = FirebaseFirestore.instance
        .collection('videos')
        .where('subCategoryId', isEqualTo: widget.subCategoryId)
        .where('language', isEqualTo: _languageCode)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: videosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final videos = snapshot.data?.docs ?? [];
          if (videos.isEmpty) {
            return const Center(child: Text('لا توجد فيديوهات في هذا القسم'));
          }
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final vidData = videos[index].data() as Map<String, dynamic>;
              final title = vidData['title'] as String? ?? '';
              return ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(title),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoPage(videoId: videos[index].id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddVideoDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Shows a dialog to add a new video to the current subcategory. The user
  /// enters a title and a video URL. The new video document is stored in
  /// Firestore with the current language and this subcategory ID.
  Future<void> _showAddVideoDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة فيديو جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: 'عنوان الفيديو'),
                ),
                TextField(
                  controller: urlController,
                  decoration:
                      const InputDecoration(labelText: 'رابط الفيديو'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final url = urlController.text.trim();
                if (title.isNotEmpty && url.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('videos').add({
                    'title': title,
                    'videoUrl': url,
                    'subCategoryId': widget.subCategoryId,
                    'language': _languageCode,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }
}