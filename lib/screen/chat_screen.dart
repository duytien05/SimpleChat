import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Đọc chuỗi ảnh Base64 từ Web
import 'chat_options_screen.dart';

class ChatScreen extends StatefulWidget {
  final String
      chatId; // ID phòng chat (ví dụ: 'user1_user2')
  final String currentUserId; // ID của bạn
  final String receiverName; // Tên người nhận
  final String
      receiverId; // ID người nhận để lấy dữ liệu tùy chọn

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.receiverName,
    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  // Hàm định dạng thời gian tin nhắn chi tiết (Giờ:Phút)
  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }
    DateTime dateTime = timestamp.toDate();
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute =
        dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Hàm gửi tin nhắn lên Firestore
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    String msg = _messageController.text.trim();
    _messageController
        .clear(); // Xóa chữ ô nhập ngay lập tức

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': widget.currentUserId,
      'text': msg,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Cập nhật tin nhắn cuối cùng ra ngoài danh sách chat
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': msg,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // THANH APP BAR MÀU XANH BLUE VỚI ĐẦY ĐỦ ICON CHỨC NĂNG BÊN PHẢI
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0068FF),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.receiverName,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone,
                color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Chức năng gọi điện đang phát triển')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call,
                color: Colors.white, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Chức năng gọi video đang phát triển')),
              );
            },
          ),
          IconButton(
            icon:
                const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatOptionsScreen(
                    currentUserId: widget.currentUserId,
                    receiverId: widget.receiverId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // VÙNG HIỂN THỊ TIN NHẮN REALTIME KÈM THỜI GIAN CHI TIẾT
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text(
                          "Hãy gửi tin nhắn đầu tiên!",
                          style: TextStyle(
                              color: Colors.grey)));
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data()
                        as Map<String, dynamic>;
                    bool isMe = data['senderId'] ==
                        widget.currentUserId;
                    String timeStr = _formatMessageTime(
                        data['timestamp'] as Timestamp?);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // Căn lề trên cùng cho avatar và tin nhắn văn bản dài
                        children: [
                          // 1. CHỈ HIỂN THỊ AVATAR ĐỐI PHƯƠNG NẾU TIN NHẮN KHÔNG PHẢI CỦA MÌNH (isMe == false)
                          if (!isMe) ...[
                            ReceiverAvatarWidget(
                              receiverId: widget.receiverId,
                              receiverName:
                                  widget.receiverName,
                            ),
                            const SizedBox(
                                width:
                                    8), // Khoảng cách giữa avatar và bong bóng chat
                          ],

                          // 2. BONG BÓNG TIN NHẮN VÀ THỜI GIAN CHI TIẾT
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment
                                      .start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(
                                          12),
                                  constraints:
                                      BoxConstraints(
                                    // Giới hạn bong bóng chat tối đa chiếm 65% chiều rộng màn hình để không đẩy lệch giao diện Web
                                    maxWidth: MediaQuery.of(
                                                context)
                                            .size
                                            .width *
                                        0.65,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(
                                            0xFF0068FF)
                                        : const Color(
                                            0xFFF1F0F0),
                                    borderRadius:
                                        BorderRadius.only(
                                      topLeft: const Radius
                                          .circular(16),
                                      topRight: const Radius
                                          .circular(16),
                                      bottomLeft: isMe
                                          ? const Radius
                                              .circular(16)
                                          : Radius.zero,
                                      bottomRight: isMe
                                          ? Radius.zero
                                          : const Radius
                                              .circular(16),
                                    ),
                                    border: isMe
                                        ? null
                                        : Border.all(
                                            color:
                                                Colors.grey[
                                                    200]!),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(
                                                0.02),
                                        blurRadius: 2,
                                        offset:
                                            const Offset(
                                                0, 1),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    data['text'] ?? '',
                                    style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors
                                                .black87,
                                        fontSize: 15),
                                  ),
                                ),
                                // HIỂN THỊ CHI TIẾT THỜI GIAN DƯỚI BONG BÓNG CHAT
                                if (timeStr.isNotEmpty)
                                  Padding(
                                    padding:
                                        EdgeInsets.only(
                                            left: isMe
                                                ? 0
                                                : 4,
                                            right: isMe
                                                ? 4
                                                : 0,
                                            top: 3,
                                            bottom: 2),
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(
                                          color: Colors
                                              .grey[500],
                                          fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // THANH NHẬP TIN NHẮN MỚI
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(
                horizontal: 6.0, vertical: 8.0),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.insert_emoticon,
                        color: Color(0xFF5f6368), size: 26),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.grey[300]!,
                            width: 0.8),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: "Nhập tin nhắn...",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 15),
                          contentPadding:
                              EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_none,
                        color: Color(0xFF5f6368), size: 26),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.image_outlined,
                        color: Color(0xFF5f6368), size: 26),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.send,
                        color: Color(0xFF0068FF), size: 26),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENT TỰ ĐỘNG MAP AVATAR REALTIME TỪ FIRESTORE
// ==========================================
class ReceiverAvatarWidget extends StatelessWidget {
  final String receiverId;
  final String receiverName;

  const ReceiverAvatarWidget({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  // Hàm xử lý ảnh (Tương thích chuỗi dữ liệu Base64 từ bộ nhớ Web và Network link)
  ImageProvider? _parseAvatar(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64String = photoUrl.split(',')[1];
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .snapshots(),
      builder: (context, snapshot) {
        String photoUrl = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          var data =
              snapshot.data!.data() as Map<String, dynamic>;
          photoUrl = data['photoUrl'] ?? '';
        }

        final imageProvider = _parseAvatar(photoUrl);

        return CircleAvatar(
          radius:
              18, // Kích thước avatar nhỏ gọn đồng bộ thanh lịch
          backgroundColor: const Color(0xFF0068FF),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? Text(
                  receiverName.isNotEmpty
                      ? receiverName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                )
              : null,
        );
      },
    );
  }
}
