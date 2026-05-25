import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../../widget/message_bubble.dart';
import 'options_screen.dart';
import '../core/constants/app_colors.dart';
import '../l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  const ChatScreen(this.user, {Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messages = [
    Message(
      text: "Chào bạn",
      isMe: false,
      time: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    Message(
      text: "Chào! Bạn khỏe không?",
      isMe: true,
      time: DateTime.now().subtract(const Duration(minutes: 9)),
    ),
    Message(
      text: "Mình khỏe, bạn đang làm gì?",
      isMe: false,
      time: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    Message(
      text: "Mình đang code Flutter",
      isMe: true,
      time: DateTime.now().subtract(const Duration(minutes: 7)),
    ),
  ];

  final controller = TextEditingController();

  void sendMessage() {
    if (controller.text.isEmpty) return;

    setState(() {
      messages.add(
        Message(text: controller.text, isMe: true, time: DateTime.now()),
      );
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(widget.user.name),

        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Call feature")));
            },
          ),

          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Video call feature")),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OptionsScreen(widget.user)),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,

              itemBuilder: (context, index) {
                return MessageBubble(messages[index]);
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,

            child: Row(
              children: [
                /// STICKER
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {
                    print("Sticker clicked");
                  },
                ),

                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.messages,
                      border: InputBorder.none,
                    ),
                  ),
                ),

                IconButton(icon: const Icon(Icons.mic), onPressed: () {}),

                IconButton(icon: const Icon(Icons.image), onPressed: () {}),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
