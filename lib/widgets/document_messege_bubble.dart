import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_interaction_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class DocumentMessageBubble extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final String messageId;
  final String chatId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserPhoto;

  const DocumentMessageBubble({
    Key? key,
    required this.messageData,
    required this.messageId,
    required this.chatId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserPhoto,
  }) : super(key: key);

  Future<void> _downloadDocument(String fileUrl,
      String rawFileName, String rawFileType) async {
    try {
      if (fileUrl.isEmpty) return;

      String ext =
          rawFileType.toLowerCase().replaceAll('.', '');
      if (ext.isEmpty) {
        ext = rawFileName.contains('.')
            ? rawFileName.split('.').last.toLowerCase()
            : 'pdf';
      }

      String fileName = rawFileName;
      if (!fileName.toLowerCase().endsWith('.$ext')) {
        fileName = '$fileName.$ext';
      }

      if (fileUrl.startsWith('data:')) {
        if (kIsWeb) {
          final parts = fileUrl.split(',');
          final base64Data =
              parts.length > 1 ? parts[1] : parts[0];

          String mimeType = 'application/octet-stream';
          switch (ext) {
            case 'docx':
              mimeType =
                  'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
              break;
            case 'doc':
              mimeType = 'application/msword';
              break;
            case 'pptx':
              mimeType =
                  'application/vnd.openxmlformats-officedocument.presentationml.presentation';
              break;
            case 'ppt':
              mimeType = 'application/vnd.ms-powerpoint';
              break;
            case 'xlsx':
              mimeType =
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
              break;
            case 'xls':
              mimeType = 'application/vnd.ms-excel';
              break;
            case 'pdf':
              mimeType = 'application/pdf';
              break;
          }

          final Uint8List bytes = base64Decode(base64Data);
          final blob = html.Blob([bytes], mimeType);
          final url =
              html.Url.createObjectUrlFromBlob(blob);

          final anchor = html.AnchorElement(href: url)
            ..target = '_blank'
            ..download = fileName;
          html.document.body?.children.add(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(url);
        } else {
          final uri = Uri.parse(fileUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri,
                mode: LaunchMode.externalApplication);
          }
        }
      } else {
        final uri = Uri.parse(fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri,
              mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải file: $e");
    }
  }

  void _showShareToHubDialog(BuildContext context) {
    final titleController = TextEditingController(
        text: messageData['fileName'] ?? 'Tài liệu');
    final descController = TextEditingController();
    String selectedCategory = 'Công nghệ thông tin';

    final categories = [
      'Công nghệ thông tin',
      'Kinh tế - MKT',
      'Ngoại ngữ',
      'Kỹ thuật',
      'Khác'
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chia sẻ lên Hub Học Tập'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên tài liệu hiển thị',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả ngắn về tài liệu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục ngành/môn học',
                        border: OutlineInputBorder(),
                      ),
                      items: categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(
                              () => selectedCategory = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF0068FF),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);

                    await ChatInteractionService
                        .shareDocumentToPublicHub(
                      chatId: chatId,
                      messageId: messageId,
                      title: titleController.text.trim(),
                      description:
                          descController.text.trim(),
                      category: selectedCategory,
                      fileUrl: messageData['fileUrl'] ?? '',
                      fileType:
                          messageData['fileType'] ?? 'pdf',
                      fileSize:
                          messageData['fileSize'] ?? '0 KB',
                      uploadedBy: currentUserId,
                      uploaderName: currentUserName,
                      uploaderPhoto: currentUserPhoto,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text(
                              'Đã đưa tài liệu lên Hub Học Tập thành công!'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Đăng lên Hub',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe =
        messageData['senderId'] == currentUserId;
    final String fileName =
        messageData['fileName'] ?? 'Tài liệu';
    final String fileSize = messageData['fileSize'] ?? '';
    final String fileUrl = messageData['fileUrl'] ?? '';
    final String fileType =
        (messageData['fileType'] ?? 'pdf').toLowerCase();
    final bool isSharedToHub =
        messageData['isSharedToHub'] ?? false;

    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = Colors.orange;

    if (fileType.contains('pdf')) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (fileType.contains('doc')) {
      fileIcon = Icons.description;
      iconColor = Colors.blue;
    } else if (fileType.contains('ppt')) {
      fileIcon = Icons.slideshow;
      iconColor = Colors.deepOrange;
    } else if (fileType.contains('xls')) {
      fileIcon = Icons.table_chart;
      iconColor = Colors.green;
    }

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF0068FF)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(fileIcon,
                      color: iconColor, size: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileSize,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white70
                              : Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.download,
                    color: isMe
                        ? Colors.white
                        : Colors.black87,
                  ),
                  onPressed: () => _downloadDocument(
                      fileUrl, fileName, fileType),
                ),
              ],
            ),
            const Divider(
                height: 12, color: Colors.white24),
            InkWell(
              onTap: isSharedToHub
                  ? null
                  : () => _showShareToHubDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 2.0),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSharedToHub
                          ? Icons.check_circle
                          : Icons.cloud_upload,
                      size: 15,
                      color: isSharedToHub
                          ? (isMe
                              ? Colors.greenAccent
                              : Colors.green)
                          : (isMe
                              ? Colors.white
                              : const Color(0xFF0068FF)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSharedToHub
                          ? 'Đã công khai trên Hub'
                          : 'Đẩy lên Hub Tài Liệu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSharedToHub
                            ? (isMe
                                ? Colors.greenAccent
                                : Colors.green)
                            : (isMe
                                ? Colors.white
                                : const Color(0xFF0068FF)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
