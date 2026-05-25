import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../core/providers/locale_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60)),

          const SizedBox(height: 15),

          Text(
            user?["name"] ?? "",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(
            user?["email"] ?? "",
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 30),

          ListTile(
            leading: const Icon(Icons.phone),
            title: Text(AppLocalizations.of(context)!.phone),
            subtitle: Text(user?["mobile"] ?? ""),
          ),

          ListTile(
            leading: const Icon(Icons.cake),
            title: Text(AppLocalizations.of(context)!.birthday),
            subtitle: Text(user?["birthday"] ?? ""),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)!.language),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text("Tiếng Việt"),
                        onTap: () {
                          Provider.of<LocaleProvider>(
                            context,
                            listen: false,
                          ).setLocale(const Locale('vi'));
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text("English"),
                        onTap: () {
                          Provider.of<LocaleProvider>(
                            context,
                            listen: false,
                          ).setLocale(const Locale('en'));
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(AppLocalizations.of(context)!.editProfile),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              AppLocalizations.of(context)!.logout,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () {
              AuthService.currentUser = null;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
