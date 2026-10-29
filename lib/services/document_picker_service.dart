import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'chat_interaction_service.dart';

class DocumentPickerService {
  static Future<void> pickAndSendDocument({
    required BuildContext context,
    required String chatId,
    required String currentUserId,
    required String currentUserName,
    required bool isGroup,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt',
          'zip'
        ],
        withData: true,
      );

      if (result != null &&
          result.files.first.bytes != null) {
        final file = result.files.first;
        String fileName = file.name;
        String fileExt =
            (file.extension ?? 'pdf').toLowerCase();

        double sizeInMb = file.size / (1024 * 1024);
        if (sizeInMb > 0.8) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              content: Text(
                  'File vượt quá 800KB. Vui lòng chọn file nhỏ hơn để lưu trực tiếp trên Firestore!'),
            ),
          );
          return;
        }

        String fileSizeStr =
            '${(file.size / 1024).toStringAsFixed(1)} KB';

        final bytes = file.bytes!;
        String base64Str = base64Encode(bytes);
        String mimeType = _getMimeType(fileExt);
        String fileDataUrl =
            'data:$mimeType;base64,$base64Str';

        await ChatInteractionService.sendMessageWithStatus(
          chatId: chatId,
          senderId: currentUserId,
          senderName: currentUserName,
          messageText: fileName,
          isGroup: isGroup,
          type: 'document',
          fileUrl: fileDataUrl,
          fileName: fileName,
          fileType: fileExt,
          fileSize: fileSizeStr,
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Gửi tài liệu thành công!'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi gửi tài liệu: $e'),
        ),
      );
    }
  }

  static String _getMimeType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}
