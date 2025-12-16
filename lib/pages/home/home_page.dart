import 'package:flutter/material.dart';
import 'package:BookMate/pages/home/library_page.dart';
import 'package:BookMate/pages/profile/profile_page.dart';
import 'package:BookMate/pages/home/search_page.dart';

class HomePage extends StatefulWidget {
  final String? email; // Nullable email, bisa null

  // Konstruktor default menerima email
  const HomePage({super.key, this.email});

  // Konstruktor untuk guest, emailnya null
  const HomePage.guest({super.key}) : email = null;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Membuat halaman sesuai dengan email yang ada
    _pages = [
      HomeLibrary(email: widget.email ?? ""),
      SearchPage(email: widget.email ?? ""),
      ProfilePage(email: widget.email),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.brown[300], // Soft brown
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          selectedItemColor: Colors.brown[700], // Brown color for selected
          unselectedItemColor: Colors.white70, // Lighter color for unselected
          elevation: 5, // Add shadow for a floating effect
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              label: 'Library',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
