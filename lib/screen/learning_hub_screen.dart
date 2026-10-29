import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/document_service.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({Key? key}) : super(key: key);

  @override
  State<LearningHubScreen> createState() =>
      _LearningHubScreenState();
}

class _LearningHubScreenState
    extends State<LearningHubScreen> {
  final DocumentService _docService = DocumentService();
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Công nghệ thông tin',
    'Kinh tế - MKT',
    'Ngoại ngữ',
    'Kỹ thuật',
    'Khác'
  ];

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
      debugPrint("Lỗi tải file từ Hub: $e");
    }
  }

  Widget _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf,
            color: Colors.red, size: 36);
      case 'docx':
      case 'doc':
        return const Icon(Icons.description,
            color: Colors.blue, size: 36);
      case 'pptx':
      case 'ppt':
        return const Icon(Icons.slideshow,
            color: Colors.deepOrange, size: 36);
      case 'xlsx':
      case 'xls':
        return const Icon(Icons.table_chart,
            color: Colors.green, size: 36);
      case 'zip':
      case 'rar':
        return const Icon(Icons.folder_zip,
            color: Colors.amber, size: 36);
      default:
        return const Icon(Icons.insert_drive_file,
            color: Colors.grey, size: 36);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 2,
        backgroundColor: const Color(0xFF0068FF),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'HUB HỌC TẬP & TÀI LIỆU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0068FF),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.black87,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child:
                StreamBuilder<List<Map<String, dynamic>>>(
              stream: _docService.getPublicDocuments(
                  category: _selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child:
                          Text('Lỗi: ${snapshot.error}'));
                }
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                        'Chưa có tài liệu nào trong mục này.'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final String title = data['title'] ??
                        data['fileName'] ??
                        'Tài liệu';
                    final String desc =
                        data['description'] ?? '';
                    final String fileUrl =
                        data['fileUrl'] ?? '';
                    final String fileName =
                        data['fileName'] ?? title;
                    final String fileType =
                        data['fileType'] ?? 'docx';
                    final String fileSize =
                        data['fileSize'] ?? '';
                    final String uploaderName =
                        data['uploaderName'] ??
                            'Được chia sẻ từ Chat';

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6),
                        leading: _getFileIcon(fileType),
                        title: Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (fileSize
                                    .isNotEmpty) ...[
                                  Text(
                                    fileSize,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors
                                            .grey[600]),
                                  ),
                                  const Text(' • ',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Colors.grey)),
                                ],
                                Expanded(
                                  child: Text(
                                    'Đăng bởi: $uploaderName',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors
                                            .grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow
                                        .ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                              Icons.download_rounded,
                              color: Color(0xFF0068FF),
                              size: 28),
                          tooltip: 'Tải tài liệu về máy',
                          onPressed: () =>
                              _downloadDocument(fileUrl,
                                  fileName, fileType),
                        ),
                        onTap: () => _downloadDocument(
                            fileUrl, fileName, fileType),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
