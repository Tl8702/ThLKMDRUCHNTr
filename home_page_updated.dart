import 'package:flutter/material.dart';
import 'books_page_updated.dart';
import 'my_list_page_updated.dart';
import 'courses_page.dart';
import 'profile_page.dart';
import '../widgets/home_categories_page_updated.dart';

/// Main page with bottom navigation. This updated version uses
/// [BooksPageUpdated] instead of the original BooksPage to allow opening
/// PDF viewer pages for books. The rest of the layout remains the same.
class HomePageUpdated extends StatefulWidget {
  const HomePageUpdated({super.key});

  @override
  State<HomePageUpdated> createState() => _HomePageUpdatedState();
}

class _HomePageUpdatedState extends State<HomePageUpdated> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomeCategoriesPageUpdated(),
      BooksPageUpdated(),
      MyListPageUpdated(),
      CoursesPage(),
      ProfilePage(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'الكتب',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'قائمتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'الدورات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}