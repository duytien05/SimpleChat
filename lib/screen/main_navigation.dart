import 'package:flutter/material.dart';
import 'chat_list_screen.dart';
import 'contacts_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);
  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ChatListScreen(),
    const ContactsScreen(),
    const Center(
        child:
            Text('Khám phá')), // Làm tĩnh để kịp deadline
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0068FF),
        unselectedItemColor: Colors.grey,
        onTap: (index) =>
            setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Tin nhắn'),
          BottomNavigationBarItem(
              icon: Icon(Icons.contacts), label: 'Danh bạ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore), label: 'Khám phá'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}
