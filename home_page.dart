import 'package:flutter/material.dart';
import 'books_page.dart';
import 'my_list_page.dart';
import 'courses_page.dart';
import 'profile_page.dart';
import '../widgets/home_categories_page.dart';

/// Main page with bottom navigation. This page holds five tabs:
///   1. Home categories - shows the sections and advertisements.
///   2. Books page - lists books by category.
///   3. My List page - shows the user's saved favourites.
///   4. Courses page - placeholder for future courses.
///   5. Profile page - user account and settings.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // List of pages corresponding to each bottom navigation tab.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomeCategoriesPage(),
      BooksPage(),
      MyListPage(),
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
