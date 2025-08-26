import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'book_viewer_page.dart';

/// Displays a list of book categories and a subset of books in each category.
///
/// This page is similar to [BooksPage] but navigates to [BookViewerPage]
/// when a book is tapped. It fetches the main categories from Firestore
/// filtered by the currently selected language. For each category, it listens
/// to the corresponding `books` collection and shows a horizontally scrollable
/// row of book thumbnails. Administrators see a floating action button that
/// allows them to add a new book via a simple dialog.
class BooksPageUpdated extends StatefulWidget {
  const BooksPageUpdated({super.key});

  @override
  State<BooksPageUpdated> createState() => _BooksPageUpdatedState();
}

class _BooksPageUpdatedState extends State<BooksPageUpdated> {
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
    // Stream of main categories filtered by language.
    final categoriesStream = FirebaseFirestore.instance
        .collection('categories_main')
        .where('language', isEqualTo: _languageCode)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        title: const Text('الكتب'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: categoriesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data?.docs ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Text(
                'لا توجد أقسام كتب متاحة',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final catDoc = categories[index];
              final catData = catDoc.data() as Map<String, dynamic>;
              final title = catData['title'] as String? ?? '';
              final booksStream = FirebaseFirestore.instance
                  .collection('books')
                  .where('categoryId', isEqualTo: catDoc.id)
                  .where('language', isEqualTo: _languageCode)
                  .snapshots();
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to a page showing all books in this category.
                          },
                          child: const Text('إظهار الكل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: booksStream,
                        builder: (context, bookSnapshot) {
                          if (bookSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final books = bookSnapshot.data?.docs ?? [];
                          if (books.isEmpty) {
                            return const Text('لا توجد كتب في هذا القسم');
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: books.length,
                            itemBuilder: (context, bookIndex) {
                              final bookData = books[bookIndex].data()
                                  as Map<String, dynamic>;
                              final bookTitle =
                                  bookData['title'] as String? ?? '';
                              final thumbnail =
                                  bookData['thumbnailUrl'] as String?;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BookViewerPage(
                                        bookId: books[bookIndex].id,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  margin:
                                      const EdgeInsets.only(right: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: thumbnail != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  thumbnail,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: Colors.grey.shade200,
                                                ),
                                                child: const Icon(
                                                  Icons.book,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        bookTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBookDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Shows a dialog that allows the admin to add a new book. The user is
  /// prompted to enter a title and a URL to the PDF file. Once saved, the
  /// book is stored under the `books` collection with the current language and
  /// selected category. For simplicity, this implementation assigns the book
  /// to the first available category. In a real app you would let the user
  /// choose the category.
  Future<void> _showAddBookDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    // Load categories to select the first as default for demonstration.
    final catsSnapshot = await FirebaseFirestore.instance
        .collection('categories_main')
        .where('language', isEqualTo: _languageCode)
        .get();
    final categoryId = catsSnapshot.docs.isNotEmpty
        ? catsSnapshot.docs.first.id
        : null;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة كتاب جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: 'عنوان الكتاب'),
                ),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'رابط ملف PDF',
                  ),
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
                if (title.isNotEmpty && url.isNotEmpty && categoryId != null) {
                  await FirebaseFirestore.instance.collection('books').add({
                    'title': title,
                    'pdfUrl': url,
                    'categoryId': categoryId,
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