import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Đọc chuỗi Base64
import 'package:image_picker/image_picker.dart'; // Chọn ảnh từ thiết bị
import 'package:image/image.dart' as img;
import 'package:record/record.dart';
import 'chat_options_screen.dart';
import '../services/chat_interaction_service.dart';
import '../services/voice_message_bubble.dart';

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

  // Khai báo đối tượng ghi âm
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    // Mỗi khi mở phòng chat, tự động đánh dấu toàn bộ tin nhắn đối phương gửi là "Đã xem"
    ChatInteractionService.markMessagesAsRead(
      chatId: widget.chatId,
      currentUserId: widget.currentUserId,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioRecorder.dispose(); // Giải phóng bộ nhớ ghi âm
    super.dispose();
  }

  // Hàm định dạng thời gian tin nhắn chi tiết (Giờ:Phút)
  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute =
        dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Hàm giải mã chuỗi Base64 hiển thị ảnh an toàn
  ImageProvider? _parseImageBase64(String base64Str) {
    try {
      if (base64Str.startsWith('data:image')) {
        return MemoryImage(
            base64Decode(base64Str.split(',')[1]));
      }
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }

  // 1. Xử lý gửi tin nhắn chữ thông thường
  void _sendMessage() async {
    String msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    _messageController
        .clear(); // Xóa chữ ô nhập ngay lập tức để tránh gửi trùng

    await ChatInteractionService.sendMessageWithStatus(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      senderName: '',
      messageText: msg,
      isGroup: false,
      type: 'text',
    );
  }

  // 2. Xử lý chọn ảnh, nén dung lượng xuống cực nhẹ và gửi lên Firestore
  void _handleSendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        var bytes = await pickedFile.readAsBytes();
        img.Image? decoded = img.decodeImage(bytes);
        if (decoded != null) {
          // Resize chiều rộng về 500px tối ưu lưu trữ Firestore dưới 1MB
          img.Image resized =
              img.copyResize(decoded, width: 500);
          // Nén chất lượng ảnh JPG xuống 60%
          List<int> compressed =
              img.encodeJpg(resized, quality: 60);
          String base64Image =
              "data:image/jpeg;base64,${base64Encode(compressed)}";

          await ChatInteractionService
              .sendMessageWithStatus(
            chatId: widget.chatId,
            senderId: widget.currentUserId,
            senderName: '',
            messageText: base64Image,
            isGroup: false,
            type: 'image',
          );
        }
      } catch (e) {
        print("Lỗi xử lý hình ảnh: $e");
      }
    }
  }

  // 3. Xử lý Bật/Dừng Ghi âm trực tiếp đa nền tảng
  void _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        try {
          // Đọc luồng dữ liệu file ghi âm sang chuỗi Base64
          final bytes = await XFile(path).readAsBytes();
          String base64Audio =
              "data:audio/webm;base64,${base64Encode(bytes)}";

          await ChatInteractionService
              .sendMessageWithStatus(
            chatId: widget.chatId,
            senderId: widget.currentUserId,
            senderName: '',
            messageText: base64Audio,
            isGroup: false,
            type: 'audio',
          );
        } catch (e) {
          print("Lỗi mã hóa âm thanh: $e");
        }
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        // Cấu hình ghi âm bitrate thấp để giảm tải dữ liệu text lên Firestore
        await _audioRecorder.start(
          const RecordConfig(
              encoder: AudioEncoder.opus,
              bitRate: 16000,
              sampleRate: 16000),
          path: '',
        );
        setState(() {
          _isRecording = true;
        });
      }
    }
  }

  // 4. Widget render linh hoạt nội dung tin nhắn theo 'type'
  Widget _buildMessageBody(String type, String content,
      bool isRevoked, bool isMe) {
    if (isRevoked) {
      return Text(
        content,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: isMe ? Colors.black54 : Colors.black54,
          fontSize: 15,
        ),
      );
    }

    switch (type) {
      case 'image':
        var imgProvider = _parseImageBase64(content);
        return imgProvider != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image(
                  image: imgProvider,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              )
            : const Text("[Hình ảnh lỗi]",
                style: TextStyle(color: Colors.red));

      case 'audio':
        // Gọi widget xử lý âm thanh động của bạn trong thư mục services
        return VoiceMessageBubble(
          base64Audio: content,
          isMe: isMe,
        );

      default: // 'text'
        return Text(
          content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          // ============ THANH HIỂN THỊ TIN NHẮN GHIM REALTIME ============
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .snapshots(),
            builder: (context, chatSnapshot) {
              if (!chatSnapshot.hasData ||
                  !chatSnapshot.data!.exists)
                return const SizedBox.shrink();

              var chatData = chatSnapshot.data!.data()
                  as Map<String, dynamic>;
              if (chatData['pinnedMessage'] == null)
                return const SizedBox.shrink();

              var pinnedData = chatData['pinnedMessage']
                  as Map<String, dynamic>;
              String pinnedText =
                  pinnedData['message'] ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border(
                      bottom: BorderSide(
                          color: Colors.amber[200]!,
                          width: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tin nhắn đã ghim',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight:
                                    FontWeight.bold),
                          ),
                          Text(
                            pinnedText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.grey),
                      onPressed: () =>
                          ChatInteractionService
                              .unpinMessage(
                                  chatId: widget.chatId),
                    ),
                  ],
                ),
              );
            },
          ),

          // ============ VÙNG HIỂN THỊ TIN NHẮN REALTIME ============
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
                    String messageId = docs[index].id;
                    bool isMe = data['senderId'] ==
                        widget.currentUserId;
                    String timeStr = _formatMessageTime(
                        data['timestamp'] as Timestamp?);

                    bool isRevoked =
                        data['isRevoked'] ?? false;
                    String status =
                        data['status'] ?? 'sent';
                    String type = data['type'] ?? 'text';
                    String currentMessageText =
                        data['message'] ??
                            data['text'] ??
                            '';

                    return GestureDetector(
                      onLongPress: () {
                        if (!isRevoked) {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          12)),
                              title: const Text(
                                  'Tùy chọn tin nhắn',
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 16)),
                              content: const Text(
                                  'Chọn thao tác bạn muốn thực hiện với tin nhắn này.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ChatInteractionService
                                        .pinMessage(
                                      chatId: widget.chatId,
                                      messageId: messageId,
                                      messageText:
                                          currentMessageText,
                                      senderName: '',
                                      isGroup: false,
                                      type:
                                          type, // Truyền type vào hàm ghim mới
                                    );
                                  },
                                  child: const Text(
                                      'Ghim tin nhắn',
                                      style: TextStyle(
                                          color: Color(
                                              0xFF0068FF),
                                          fontWeight:
                                              FontWeight
                                                  .bold)),
                                ),
                                if (isMe)
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(
                                          context);
                                      await ChatInteractionService
                                          .revokeMessage(
                                        chatId:
                                            widget.chatId,
                                        messageId:
                                            messageId,
                                        senderName: '',
                                        isGroup: false,
                                      );
                                    },
                                    child: const Text(
                                        'Thu hồi',
                                        style: TextStyle(
                                            color:
                                                Colors.red,
                                            fontWeight:
                                                FontWeight
                                                    .bold)),
                                  ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context),
                                  child: const Text('Hủy',
                                      style: TextStyle(
                                          color:
                                              Colors.grey)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              ReceiverAvatarWidget(
                                receiverId:
                                    widget.receiverId,
                                receiverName:
                                    widget.receiverName,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment
                                        .start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                        type == 'image' &&
                                                !isRevoked
                                            ? 4
                                            : 12),
                                    constraints:
                                        BoxConstraints(
                                      maxWidth: MediaQuery.of(
                                                  context)
                                              .size
                                              .width *
                                          0.65,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: isMe
                                          ? (isRevoked
                                              ? Colors
                                                  .grey[200]
                                              : const Color(
                                                  0xFF0068FF))
                                          : const Color(
                                              0xFFF1F0F0),
                                      borderRadius:
                                          BorderRadius.only(
                                        topLeft:
                                            const Radius
                                                .circular(
                                                16),
                                        topRight:
                                            const Radius
                                                .circular(
                                                16),
                                        bottomLeft: isMe
                                            ? const Radius
                                                .circular(
                                                16)
                                            : Radius.zero,
                                        bottomRight: isMe
                                            ? Radius.zero
                                            : const Radius
                                                .circular(
                                                16),
                                      ),
                                      border: isMe &&
                                              !isRevoked
                                          ? null
                                          : Border.all(
                                              color: Colors
                                                      .grey[
                                                  200]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors
                                              .black
                                              .withOpacity(
                                                  0.02),
                                          blurRadius: 2,
                                          offset:
                                              const Offset(
                                                  0, 1),
                                        )
                                      ],
                                    ),
                                    child: _buildMessageBody(
                                        type,
                                        currentMessageText,
                                        isRevoked,
                                        isMe),
                                  ),
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
                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        if (timeStr
                                            .isNotEmpty)
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                                color: Colors
                                                        .grey[
                                                    500],
                                                fontSize:
                                                    10),
                                          ),
                                        if (isMe &&
                                            !isRevoked) ...[
                                          const SizedBox(
                                              width: 4),
                                          Text(
                                            status == 'read'
                                                ? '• Đã xem'
                                                : '• Đã gửi',
                                            style: TextStyle(
                                                color: status ==
                                                        'read'
                                                    ? const Color(
                                                        0xFF0068FF)
                                                    : Colors.grey[
                                                        500],
                                                fontSize:
                                                    10,
                                                fontWeight: status ==
                                                        'read'
                                                    ? FontWeight
                                                        .w500
                                                    : FontWeight
                                                        .normal),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ============ THANH NHẬP TIN NHẮN MỚI (Tích hợp sự kiện Chọn ảnh & Mic) ============
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
                        enabled:
                            !_isRecording, // Khóa ô nhập text khi đang ghi âm
                        decoration: InputDecoration(
                          hintText: _isRecording
                              ? "Đang ghi âm bằng Micro..."
                              : "Nhập tin nhắn...",
                          hintStyle: TextStyle(
                              color: _isRecording
                                  ? Colors.red
                                  : Colors.grey,
                              fontSize: 15),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  // Nút Ghi âm (Bấm 1 lần để bật ghi, bấm lần nữa để dừng và gửi tự động)
                  IconButton(
                    icon: Icon(
                        _isRecording
                            ? Icons.stop_circle
                            : Icons.mic_none,
                        color: _isRecording
                            ? Colors.red
                            : const Color(0xFF5f6368),
                        size: 26),
                    onPressed: _toggleRecording,
                  ),
                  // Nút Chọn hình ảnh
                  IconButton(
                    icon: const Icon(Icons.image_outlined,
                        color: Color(0xFF5f6368), size: 26),
                    onPressed: _handleSendImage,
                  ),
                  // Nút Gửi chữ thường
                  IconButton(
                    icon: const Icon(Icons.send,
                        color: Color(0xFF0068FF), size: 26),
                    onPressed:
                        _isRecording ? null : _sendMessage,
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

// Giữ nguyên Component hiển thị avatar đối phương
class ReceiverAvatarWidget extends StatelessWidget {
  final String receiverId;
  final String receiverName;

  const ReceiverAvatarWidget({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

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
          radius: 18,
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
