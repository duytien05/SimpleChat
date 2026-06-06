import 'dart:convert';
import 'package:flutter/foundation.dart'; // Để xử lý dữ liệu bytes
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // Thêm thư viện chọn ảnh
import 'package:image/image.dart'
    as img; // Thêm thư viện nén ảnh
import '../services/story_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() =>
      _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final String currentUserId =
      FirebaseAuth.instance.currentUser!.uid;
  String myName = "Người dùng";
  String myAvatar = "";

  @override
  void initState() {
    super.initState();
    _loadMyInfo();
  }

  void _loadMyInfo() async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (doc.exists && doc.data() != null) {
      setState(() {
        String name = doc.data()?['displayName'] ?? "";
        myName = name.trim().isEmpty ? "Tôi" : name;
        myAvatar = doc.data()?['photoUrl'] ?? "";
      });
    }
  }

  ImageProvider? _parseImage(String base64Str) {
    if (base64Str.trim().isEmpty) return null;
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

  void _showStoryViewer(Map<String, dynamic> storyData) {
    String name = storyData['userName'] ?? "User";
    if (name.trim().isEmpty) name = "Ẩn danh";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 40),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height:
                  MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                image: (storyData['imageUrl'] ?? '')
                        .toString()
                        .isNotEmpty
                    ? DecorationImage(
                        image: _parseImage(
                                storyData['imageUrl']) ??
                            const AssetImage(
                                'assets/default_bg.png'),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: _parseImage(
                        storyData['userAvatar'] ?? ""),
                    child: (storyData['userAvatar'] ?? "")
                            .toString()
                            .isEmpty
                        ? Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: Colors.white))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                              blurRadius: 4,
                              color: Colors.black,
                              offset: Offset(1, 1))
                        ]),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  storyData['caption'] ?? "",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm chọn ảnh thực tế và nén thành chuỗi Base64 dung lượng nhỏ
  void _createNewStoryWithImage() async {
    TextEditingController captionController =
        TextEditingController();
    XFile? pickedFile;
    bool isProcessing = false;

    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // Sử dụng StatefulBuilder để cập nhật giao diện Dialog khi chọn ảnh xong
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Đăng khoảnh khắc mới',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Khu vực chọn và hiển thị ảnh xem trước
                    GestureDetector(
                      onTap: isProcessing
                          ? null
                          : () async {
                              final XFile? image =
                                  await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null) {
                                setDialogState(() {
                                  pickedFile = image;
                                });
                              }
                            },
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius:
                              BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.grey[300]!),
                        ),
                        child: pickedFile != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                        8),
                                child: Image.network(
                                  pickedFile!.path,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                      Icons
                                          .add_photo_alternate,
                                      size: 40,
                                      color: Colors.grey),
                                  SizedBox(height: 6),
                                  Text(
                                      'Bấm để chọn ảnh thực tế',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: captionController,
                      decoration: const InputDecoration(
                          hintText: 'Hôm nay bạn thế nào?'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: isProcessing
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Hủy',
                        style:
                            TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF0068FF)),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          String text =
                              captionController.text.trim();
                          if (text.isEmpty &&
                              pickedFile == null) return;

                          setDialogState(() {
                            isProcessing = true;
                          });

                          String finalBase64Image = "";

                          // Xử lý nén ảnh sang Base64 nếu người dùng chọn ảnh thực tế
                          if (pickedFile != null) {
                            try {
                              Uint8List bytes =
                                  await pickedFile!
                                      .readAsBytes();
                              img.Image? decoded =
                                  img.decodeImage(bytes);
                              if (decoded != null) {
                                // Resize chiều rộng về 600px để tiết kiệm bộ nhớ Firestore
                                img.Image resized =
                                    img.copyResize(decoded,
                                        width: 600);
                                // Nén chất lượng JPG xuống 65% (Dung lượng ảnh chỉ còn khoảng vài chục KB)
                                List<int> compressed =
                                    img.encodeJpg(resized,
                                        quality: 65);
                                finalBase64Image =
                                    "data:image/jpeg;base64,${base64Encode(compressed)}";
                              }
                            } catch (e) {
                              print(
                                  "Lỗi mã hóa nén ảnh: $e");
                            }
                          }

                          // Gọi Service đưa lên Firestore
                          await StoryService.uploadStory(
                            userId: currentUserId,
                            userName: myName.isEmpty
                                ? "Người dùng"
                                : myName,
                            userAvatar: myAvatar,
                            imageBase64: finalBase64Image,
                            caption: text,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Đăng ngay',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Khám phá',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: const Color(0xFF0068FF),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            height: 120,
            padding:
                const EdgeInsets.symmetric(vertical: 12),
            child: StreamBuilder<QuerySnapshot>(
              stream: StoryService.getActiveStories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2)));
                }

                var storyDocs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12),
                  itemCount: storyDocs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _createNewStoryWithImage,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 14.0),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor:
                                        Colors.grey[200],
                                    backgroundImage:
                                        _parseImage(
                                            myAvatar),
                                    child: myAvatar.isEmpty
                                        ? Text(
                                            myName.isNotEmpty
                                                ? myName[0]
                                                    .toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold))
                                        : null,
                                  ),
                                  const Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 9,
                                      backgroundColor:
                                          Color(0xFF0068FF),
                                      child: Icon(Icons.add,
                                          size: 12,
                                          color:
                                              Colors.white),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text('Tin của bạn',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          Colors.black54)),
                            ],
                          ),
                        ),
                      );
                    }

                    var storyData = storyDocs[index - 1]
                        .data() as Map<String, dynamic>;

                    String name =
                        storyData['userName'] ?? "";
                    if (name.trim().isEmpty)
                      name = "Ẩn danh";
                    String avatar =
                        storyData['userAvatar'] ?? "";

                    return GestureDetector(
                      onTap: () =>
                          _showStoryViewer(storyData),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            right: 14.0),
                        child: Column(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(2.5),
                              decoration:
                                  const BoxDecoration(
                                      shape:
                                          BoxShape.circle,
                                      color: Color(
                                          0xFF0068FF)),
                              child: Container(
                                padding:
                                    const EdgeInsets.all(2),
                                decoration:
                                    const BoxDecoration(
                                        shape:
                                            BoxShape.circle,
                                        color:
                                            Colors.white),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage:
                                      _parseImage(avatar),
                                  child: avatar.isEmpty
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              color: Colors
                                                  .white))
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 60,
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87),
                                textAlign: TextAlign.center,
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
          const Expanded(
            child: Center(
              child: Text(
                "Tính năng mạng xã hội và khoảnh khắc",
                style: TextStyle(
                    color: Colors.grey, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
