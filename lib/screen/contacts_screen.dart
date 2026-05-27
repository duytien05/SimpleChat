import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_list_screen.dart';
import 'search_user_screen.dart';
import 'chat_screen.dart';
import '../l10n/app_localizations.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  // Lấy danh sách user từ Firestore
  Future<List<User>> fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
  }

  Map<String, List<User>> groupContacts(List<User> users) {
    Map<String, List<User>> map = {};
    for (User user in users) {
      String letter = user.name[0].toUpperCase();
      if (!map.containsKey(letter)) {
        map[letter] = [];
      }
      map[letter]!.add(user);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          /// ===== SEARCH HEADER =====
          Container(
            color: const Color.fromARGB(255, 239, 211, 221),
            padding: const EdgeInsets.all(10),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  /// SEARCH
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchUserScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.search,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// ADD FRIEND
                  IconButton(
                    icon: const Icon(Icons.person_add_alt, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.addFriend,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          /// ===== TAB BAR =====
          Container(
            color: Colors.white,
            child: TabBar(
              controller: tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: AppLocalizations.of(context)!.friends),
                Tab(text: AppLocalizations.of(context)!.groups),
              ],
            ),
          ),

          /// ===== BODY =====
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                // ===== FRIEND LIST =====
                FutureBuilder<List<User>>(
                  future: fetchUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No users found'));
                    }
                    final grouped = groupContacts(snapshot.data!);
                    final letters = grouped.keys.toList()..sort();
                    return ListView(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.group, color: Colors.white),
                          ),
                          title: Text(
                            "${AppLocalizations.of(context)!.friendRequest} (27)",
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!.friendRequest,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ...letters.map((letter) {
                          List<User> users = grouped[letter]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  letter,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...users.map((user) {
                                return ListTile(
                                  leading: CircleAvatar(child: Text(user.name[0])),
                                  title: Text(user.name),
                                  trailing: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.call),
                                      SizedBox(width: 10),
                                      Icon(Icons.videocam),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(user),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
                // ===== GROUP TAB =====
                Center(child: Text(AppLocalizations.of(context)!.groupList)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
