import 'package:cloud_firestore/cloud_firestore.dart';

class ChatInteractionService {
  // 1. Hàm gửi tin nhắn
  static Future<void> sendMessageWithStatus({
    required String chatId,
    required String senderId,
    required String senderName,
    required String messageText,
    required bool isGroup,
    String type = 'text',
  }) async {
    final messageData = {
      'senderId': senderId,
      'senderName': senderName,
      'message': messageText,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isRevoked': false,
      'status': 'sent',
      'readBy': [senderId],
    };

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Tối ưu nội dung hiển thị Last Message ở danh sách chat bên ngoài
    String lastMsgDisplay = messageText;
    if (type == 'image') {
      lastMsgDisplay = '[Hình ảnh]';
    } else if (type == 'audio') {
      lastMsgDisplay = '[Tin nhắn thoại]';
    }

    // Cập nhật Last Message danh sách chat bên ngoài
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .update({
      'lastMessage': isGroup
          ? '$senderName: $lastMsgDisplay'
          : lastMsgDisplay,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // 2. Hàm THU HỒI TIN NHẮN (Giữ nguyên logic cũ)
  static Future<void> revokeMessage({
    required String chatId,
    required String messageId,
    required String senderName,
    required bool isGroup,
  }) async {
    try {
      // Sửa nội dung tin nhắn trong Sub-collection thành thông báo thu hồi
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'message':
            'Tin nhắn đã bị thu hồi', // Đè dữ liệu văn bản cũ
        'type': 'text', // Trả type về text khi bị thu hồi
        'isRevoked': true,
      });

      // Cập nhật Last Message hiển thị ngoài màn hình danh sách chat
      String lastMsgDisplay = isGroup
          ? '$senderName: Tin nhắn đã bị thu hồi'
          : 'Tin nhắn đã bị thu hồi';

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'lastMessage': lastMsgDisplay,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Lỗi khi thu hồi tin nhắn: $e");
    }
  }

  // 3. Đánh dấu đã xem (Giữ nguyên logic cũ)
  static Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    final snapshot = await messagesRef.get();
    for (var doc in snapshot.docs) {
      List<dynamic> readBy = doc.data()['readBy'] ?? [];
      if (!readBy.contains(currentUserId)) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([currentUserId]),
          'status': 'read',
        });
      }
    }
  }

  // 4. TÍNH NĂNG GHIM TIN NHẮN (ĐÃ CẬP NHẬT: Thêm xử lý chữ hiển thị thanh ghim nếu ghim Ảnh/Audio)
  static Future<void> pinMessage({
    required String chatId,
    required String messageId,
    required String messageText,
    required String senderName,
    required bool isGroup,
    String type =
        'text', // Nhận thêm type để xử lý chuỗi hiển thị trên thanh ghim
  }) async {
    try {
      String pinDisplay = messageText;
      if (type == 'image') {
        pinDisplay = '[Hình ảnh]';
      } else if (type == 'audio') {
        pinDisplay = '[Tin nhắn thoại]';
      }

      // Lưu thông tin bản ghi ghim trực tiếp vào Document tổng của phòng chat
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'pinnedMessage': {
          'messageId': messageId,
          'message':
              pinDisplay, // Lưu text hoặc chữ đại diện [Hình ảnh]/[Tin nhắn thoại]
          'senderName': isGroup ? senderName : 'Đối phương',
          'pinnedAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      print("Lỗi khi ghim tin nhắn: $e");
    }
  }

  // 5. TÍNH NĂNG GỠ GHIM TIN NHẮN (Giữ nguyên logic cũ)
  static Future<void> unpinMessage(
      {required String chatId}) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'pinnedMessage': null,
      });
    } catch (e) {
      print("Lỗi khi gỡ ghim tin nhắn: $e");
    }
  }
}
