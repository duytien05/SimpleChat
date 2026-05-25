import 'package:flutter/material.dart';
import '../core/utils/mock_users.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';
import '../core/constants/app_colors.dart';
import '../services/chat_memory.dart';
import '../l10n/app_localizations.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  TextEditingController controller = TextEditingController();

  User? foundUser;
  String message = "";

  List<User> recentUsers = [mockUsers[0], mockUsers[1], mockUsers[2]];

  void searchUser() {
    String phone = controller.text.trim();

    for (User user in mockUsers) {
      if (user.phone == phone) {
        setState(() {
          foundUser = user;
          message = "";
        });
        return;
      }
    }

    setState(() {
      foundUser = null;
      message = AppLocalizations.of(context)!.phoneNotExist;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(10),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  /// BACK BUTTON
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  /// SEARCH BOX
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.search),
                          hintText: AppLocalizations.of(context)!.searchPhone,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          searchUser();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              children: [
                /// USER FOUND
                if (foundUser != null)
                  ListTile(
                    leading: CircleAvatar(child: Text(foundUser!.name[0])),
                    title: Text(foundUser!.name),
                    subtitle: Text(foundUser!.phone),
                    onTap: () {
                      ChatMemory.chats.remove(foundUser);
                      ChatMemory.chats.insert(0, foundUser!);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(foundUser!),
                        ),
                      );
                    },
                  ),

                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                if (foundUser == null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.recentSearch,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                if (foundUser == null)
                  ...recentUsers.map(
                    (user) => ListTile(
                      leading: CircleAvatar(child: Text(user.name[0])),
                      title: Text(user.name),
                      subtitle: Text(user.phone),
                      onTap: () {
                        ChatMemory.chats.remove(user);
                        ChatMemory.chats.insert(0, user);

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatScreen(user)),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
