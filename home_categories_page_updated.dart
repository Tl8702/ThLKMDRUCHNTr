import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/subcategory_page_updated.dart';

/// Updated version of the HomeCategoriesPage that opens SubcategoryPageUpdated
/// when a subcategory is tapped. It also includes a carousel for ads and
/// allows admins to add main and sub categories.
class HomeCategoriesPageUpdated extends StatefulWidget {
  const HomeCategoriesPageUpdated({super.key});

  @override
  State<HomeCategoriesPageUpdated> createState() => _HomeCategoriesPageUpdatedState();
}

class _HomeCategoriesPageUpdatedState extends State<HomeCategoriesPageUpdated> {
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
      return const Center(child: CircularProgressIndicator());
    }
    final categoriesStream = FirebaseFirestore.instance
        .collection('categories_main')
        .where('language', isEqualTo: _languageCode)
        .snapshots();
    final adsStream = FirebaseFirestore.instance
        .collection('ads')
        .where('language', whereIn: [_languageCode, 'all'])
        .where('active', isEqualTo: true)
        .snapshots();
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 150,
                child: StreamBuilder<QuerySnapshot>(
                  stream: adsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return PageView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final imageUrl = data['imageUrl'] as String?;
                        final link = data['link'] as String?;
                        return GestureDetector(
                          onTap: () {
                            if (link != null) {
                              final uri = Uri.tryParse(link);
                              if (uri != null && _isDomainAllowed(uri.host)) {
                                // TODO: integrate with url_launcher to open valid links.
                              }
                            }
                          },
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: categoriesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final categories = snapshot.data?.docs ?? [];
                    if (categories.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد أقسام متاحة',
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
                        final subCategoriesStream = FirebaseFirestore.instance
                            .collection('categories_sub')
                            .where('parentId', isEqualTo: catDoc.id)
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
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          // TODO: navigate to a page showing all items in this category.
                                        },
                                        child: const Text('إظهار الكل'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        tooltip: 'إضافة قسم فرعي',
                                        onPressed: () {
                                          _showAddSubCategoryDialog(context, catDoc.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 120,
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: subCategoriesStream,
                                  builder: (context, subSnapshot) {
                                    if (subSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final subcats = subSnapshot.data?.docs ?? [];
                                    if (subcats.isEmpty) {
                                      return const Text('لا توجد أقسام فرعية');
                                    }
                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: subcats.length,
                                      itemBuilder: (context, subIndex) {
                                        final subData = subcats[subIndex].data() as Map<String, dynamic>;
                                        final name = subData['title'] as String? ?? '';
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => SubcategoryPageUpdated(
                                                  subCategoryId: subcats[subIndex].id,
                                                  title: name,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 100,
                                            margin: const EdgeInsets.only(right: 8.0),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                            child: Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  name,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
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
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                _showAddCategoryDialog(context);
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDomainAllowed(String host) {
    const allowedDomains = {'example.com', 'example2.com'};
    return allowedDomains.contains(host);
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة قسم رئيسي'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'اسم القسم'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('categories_main').add({
                    'title': title,
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

  Future<void> _showAddSubCategoryDialog(BuildContext context, String parentId) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة قسم فرعي'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'اسم القسم الفرعي'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('categories_sub').add({
                    'title': name,
                    'parentId': parentId,
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