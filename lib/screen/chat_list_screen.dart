import 'package:flutter/material.dart';
import 'search_user_screen.dart';
import '../core/constants/app_colors.dart';
import 'chat_screen.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import '../services/chat_memory.dart';
import '../l10n/app_localizations.dart';
import 'contacts_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  void openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchUserScreen()),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      chatPage(),
      const ContactsScreen(),
      Center(child: Text(AppLocalizations.of(context)!.discover)),

      ProfileScreen(),
    ];

    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color.fromARGB(255, 189, 123, 188),
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: AppLocalizations.of(context)!.messages,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: AppLocalizations.of(context)!.contacts,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: AppLocalizations.of(context)!.discover,
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }

  Widget chatPage() {
    return Column(
      children: [
        /// APP BAR
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.only(
            top: 40,
            left: 15,
            right: 15,
            bottom: 10,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: openSearch,
                child: const Icon(Icons.search, color: Colors.white),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: GestureDetector(
                  onTap: openSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.search,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              const Icon(Icons.qr_code, color: Colors.white),

              const SizedBox(width: 15),

              const Icon(Icons.add, color: Colors.white),
            ],
          ),
        ),

        Container(
          color: Colors.white,
          child: TabBar(
            controller: tabController,
            labelColor: Colors.black,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.priority),
              Tab(text: AppLocalizations.of(context)!.others),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [chatList(), chatList()],
          ),
        ),
      ],
    );
  }

  Widget chatList() {
    List<User> demoChats = [
      User(name: "Me yeu", phone: "0900000000"),
      User(name: "Bình", phone: "0911111111"),
      User(name: "NYC", phone: "0922222222"),
    ];

    final allChats = [...ChatMemory.chats, ...demoChats];

    return ListView.builder(
      itemCount: allChats.length,
      itemBuilder: (context, index) {
        final user = allChats[index];

        return ListTile(
          leading: CircleAvatar(child: Text(user.name[0])),
          title: Text(user.name),
          subtitle: const Text("Tin nhắn..."),
          trailing: const Text("1 phút"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(user)),
            ).then((_) {
              setState(() {});
            });
          },
        );
      },
    );
  }
}
