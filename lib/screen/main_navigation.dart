import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_list_screen.dart';
import 'contacts_screen.dart';
import 'discovery_screen.dart';
import 'profile_screen.dart';
import 'incoming_call_screen.dart';
import 'learning_hub_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  StreamSubscription<QuerySnapshot>? _callSubscription;

  final List<Widget> _screens = [
    const ChatListScreen(),
    const ContactsScreen(),
    const DiscoveryScreen(),
    const ProfileScreen(),
    const LearningHubScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenIncomingCalls();
  }

  void _listenIncomingCalls() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverIds',
            arrayContains: currentUser.uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final callData = snapshot.docs.first.data()
            as Map<String, dynamic>;

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncomingCallScreen(
                callId: callData['callId'] ?? '',
                chatId: callData['chatId'] ?? '',
                callerId: callData['callerId'] ?? '',
                callerDisplayName:
                    callData['callerDisplayName'] ??
                        'Người gọi',
                callerPhotoUrl:
                    callData['callerPhotoUrl'] ?? '',
                hasVideo: callData['hasVideo'] ?? false,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

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
            icon: Icon(Icons.message),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Danh bạ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Khám phá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Hub Học Tập',
          ),
        ],
      ),
    );
  }
}
