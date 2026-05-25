import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../core/constants/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final Message msg;

  const MessageBubble(this.msg, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),

      child: Column(
        crossAxisAlignment: msg.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.isMe ? AppColors.primary : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: msg.isMe ? const Radius.circular(12) : Radius.zero,
                bottomRight: msg.isMe ? Radius.zero : const Radius.circular(12),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            "${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
