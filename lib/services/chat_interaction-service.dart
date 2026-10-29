import 'package:cloud_firestore/cloud_firestore.dart';

class ChatInteractionService {
  static Future<void> sendMessageWithStatus({
    required String chatId,
    required String senderId,
    required String senderName,
    required String messageText,
    required bool isGroup,
    String type = 'text',
    String? fileUrl,
    String? fileName,
    String? fileType,
    String? fileSize,
  }) async {
    final messageData = <String, dynamic>{
      'senderId': senderId,
      'senderName': senderName,
      'message': messageText,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isRevoked': false,
      'status': 'sent',
      'readBy': [senderId],
    };

    if (type == 'document') {
      messageData['fileUrl'] = fileUrl ?? '';
      messageData['fileName'] = fileName ?? 'Tài liệu';
      messageData['fileType'] = fileType ?? 'pdf';
      messageData['fileSize'] = fileSize ?? '0 MB';
      messageData['isSharedToHub'] = false;
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    String lastMsgDisplay = messageText;
    if (type == 'image') {
      lastMsgDisplay = '[Hình ảnh]';
    } else if (type == 'audio') {
      lastMsgDisplay = '[Tin nhắn thoại]';
    } else if (type == 'document') {
      lastMsgDisplay =
          '[Tài liệu] ${fileName ?? "File đính kèm"}';
    }

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

  static Future<void> shareDocumentToPublicHub({
    required String chatId,
    required String messageId,
    required String title,
    required String description,
    required String category,
    required String fileUrl,
    required String fileType,
    required String fileSize,
    required String uploadedBy,
    required String uploaderName,
    required String uploaderPhoto,
  }) async {
    try {
      String docId = FirebaseFirestore.instance
          .collection('documents')
          .doc()
          .id;

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(docId)
          .set({
        'docId': docId,
        'title': title,
        'description': description,
        'category': category,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileSize': fileSize,
        'uploadedBy': uploadedBy,
        'uploaderName': uploaderName,
        'uploaderPhoto': uploaderPhoto,
        'sourceChatId': chatId,
        'isPublic': true,
        'downloadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isSharedToHub': true});
    } catch (e) {
      print("Lỗi khi chia sẻ tài liệu lên Hub: $e");
    }
  }

  static Future<void> revokeMessage({
    required String chatId,
    required String messageId,
    required String senderName,
    required bool isGroup,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'message': 'Tin nhắn đã bị thu hồi',
        'type': 'text',
        'isRevoked': true,
      });

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

  static Future<void> pinMessage({
    required String chatId,
    required String messageId,
    required String messageText,
    required String senderName,
    required bool isGroup,
    String type = 'text',
  }) async {
    try {
      String pinDisplay = messageText;
      if (type == 'image') {
        pinDisplay = '[Hình ảnh]';
      } else if (type == 'audio') {
        pinDisplay = '[Tin nhắn thoại]';
      } else if (type == 'document') {
        pinDisplay = '[Tài liệu] $messageText';
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'pinnedMessage': {
          'messageId': messageId,
          'message': pinDisplay,
          'senderName': isGroup ? senderName : 'Đối phương',
          'pinnedAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      print("Lỗi khi ghim tin nhắn: $e");
    }
  }

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
