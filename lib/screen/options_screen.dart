import 'package:flutter/material.dart';
import 'package:mobile/screen/profile_screen.dart';
import '../models/user_model.dart';
import '../core/constants/app_colors.dart';
import '../l10n/app_localizations.dart';

class OptionsScreen extends StatefulWidget {
  final User user;

  const OptionsScreen(this.user, {Key? key}) : super(key: key);

  @override
  _OptionsScreenState createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  bool bestFriend = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.options),
        backgroundColor: AppColors.primary,
      ),

      body: ListView(
        children: [
          const SizedBox(height: 20),

          CircleAvatar(
            radius: 50,
            child: Text(
              widget.user.name[0],
              style: const TextStyle(fontSize: 30),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              widget.user.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 30),

          ListTile(
            leading: const Icon(Icons.person),
            title: Text(AppLocalizations.of(context)!.profilePage),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.star),
            title: Text(AppLocalizations.of(context)!.closeFriend),

            value: bestFriend,

            onChanged: (value) {
              setState(() {
                bestFriend = value;
              });
            },
          ),

          ListTile(
            leading: const Icon(Icons.group_add),
            title: Text(AppLocalizations.of(context)!.createGroup),

            onTap: () {
              print("Create group");
            },
          ),
        ],
      ),
    );
  }
}
