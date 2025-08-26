import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// A simple PDF viewer page that loads a book from Firestore by its ID.
///
/// The book document is expected to contain a `pdfUrl` field pointing to
/// the PDF file and optionally a `title`. The PDF is displayed using
/// [SfPdfViewer.network] from the syncfusion_flutter_pdfviewer package.
class BookViewerPage extends StatefulWidget {
  final String bookId;
  const BookViewerPage({super.key, required this.bookId});

  @override
  State<BookViewerPage> createState() => _BookViewerPageState();
}

class _BookViewerPageState extends State<BookViewerPage> {
  String? _title;
  String? _pdfUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final doc = await FirebaseFirestore.instance
        .collection('books')
        .doc(widget.bookId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _title = data['title'] as String?;
        _pdfUrl = data['pdfUrl'] as String?;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title ?? 'قراءة الكتاب'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pdfUrl == null
              ? const Center(child: Text('تعذر العثور على الكتاب'))
              : SfPdfViewer.network(_pdfUrl!),
    );
  }
}