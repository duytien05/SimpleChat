import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatOptionsScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;

  const ChatOptionsScreen({
    super.key,
    required this.currentUserId,
    required this.receiverId,
  });

  @override
  State<ChatOptionsScreen> createState() =>
      _ChatOptionsScreenState();
}

class _ChatOptionsScreenState
    extends State<ChatOptionsScreen> {
  // Hàm xử lý kết bạn trực tiếp lên mảng 'friends' trên Firestore
  void _addFriend() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .update({
      'friends': FieldValue.arrayUnion([widget.receiverId])
    });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .update({
      'friends':
          FieldValue.arrayUnion([widget.currentUserId])
    });
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Đã gửi lời mời và kết bạn thành công!')),
    );
  }

  // Hàm xử lý mở hộp thoại xác nhận tạo nhóm chat độc lập
  void _showCreateGroupDialog(String receiverName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: const Text('Xác nhận tạo nhóm'),
          content: Text(
              'Bạn có muốn tạo nhóm với $receiverName không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                  context), // Chọn Không: đóng dialog
              child: const Text('Không',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0068FF)),
              onPressed: () async {
                Navigator.pop(
                    context); // Đóng hộp thoại trước

                // Thực hiện tạo phòng chat nhóm mới trong Firestore
                DocumentReference newChatGroup =
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .add({
                  'isGroup': true,
                  'groupName': 'Nhóm của $receiverName',
                  'lastMessage':
                      'Nhóm mới đã được khởi tạo',
                  'lastMessageTime':
                      FieldValue.serverTimestamp(),
                  'participants': [
                    widget.currentUserId,
                    widget.receiverId
                  ],
                });

                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Đã tạo nhóm thành công! ID: ${newChatGroup.id}')),
                );
                Navigator.pop(
                    context); // Quay về hẳn màn hình chat đơn cũ
              },
              child: const Text('Có',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[
          100], // Thiết kế màu nền tổng thể là màu xám
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(
            0xFF0068FF), // Thanh trên cùng viền màu xanh blue
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Tùy chọn',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
      // Lấy thông tin cá nhân Realtime của đối phương từ Firestore
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.receiverId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData ||
              !userSnapshot.data!.exists) {
            return const Center(
                child: Text(
                    "Không tìm thấy thông tin người dùng"));
          }

          var userData = userSnapshot.data!.data()
              as Map<String, dynamic>;
          String name =
              userData['displayName'] ?? 'Người dùng';
          String email =
              userData['email'] ?? 'Chưa cập nhật';
          String birthDate =
              userData['birthDate'] ?? 'Chưa cập nhật';
          String avatarUrl = userData['photoUrl'] ?? '';

          // Lấy thông tin tài khoản cá nhân hiện tại để kiểm tra mảng bạn bè (friends)
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.currentUserId)
                .snapshots(),
            builder: (context, mySnapshot) {
              bool isFriend = false;
              if (mySnapshot.hasData &&
                  mySnapshot.data!.exists) {
                var myData = mySnapshot.data!.data()
                    as Map<String, dynamic>;
                List<dynamic> myFriends =
                    myData['friends'] ?? [];
                isFriend =
                    myFriends.contains(widget.receiverId);
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Hiển thị ảnh đại diện bo tròn lớn đẹp mắt
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[100],
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: Color(0xFF0068FF)))
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 24),

                    // Khối hiển thị thông tin chi tiết cá nhân dạng danh sách thẻ trắng sạch sẽ
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                                Icons.cake_outlined,
                                color: Color(0xFF0068FF)),
                            title: const Text('Ngày sinh',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13)),
                            subtitle: Text(birthDate,
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight:
                                        FontWeight.w500)),
                          ),
                          Divider(
                              height: 1,
                              color: Colors.grey[200]),
                          ListTile(
                            leading: const Icon(
                                Icons.email_outlined,
                                color: Color(0xFF0068FF)),
                            title: const Text(
                                'Email đăng ký',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13)),
                            subtitle: Text(email,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Khối quản lý trạng thái kết bạn và tạo nhóm chat
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          // Kiểm tra điều kiện hiển thị nút Kết Bạn hoặc Đã là Bạn Bè có dấu tick xanh
                          isFriend
                              ? const ListTile(
                                  leading: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 26),
                                  title: Text(
                                    'Đã là bạn bè',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                )
                              : ListTile(
                                  leading: const Icon(
                                      Icons
                                          .person_add_alt_1,
                                      color: Color(
                                          0xFF0068FF)),
                                  title: const Text(
                                      'Thêm bạn bè',
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w600)),
                                  trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey),
                                  onTap: _addFriend,
                                ),
                          Divider(
                              height: 1,
                              color: Colors.grey[200]),
                          ListTile(
                            leading: const Icon(
                                Icons.group_add_outlined,
                                color: Color(0xFF0068FF)),
                            title: const Text('Tạo nhóm',
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight.w600)),
                            trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey),
                            onTap: () =>
                                _showCreateGroupDialog(
                                    name),
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
    );
  }
}
