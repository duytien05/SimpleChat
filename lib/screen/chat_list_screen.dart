import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  // Hàm hỗ trợ tính toán thời gian hiển thị
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0068FF),
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SearchScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.search,
                    color: Colors.white70, size: 20),
                SizedBox(width: 10),
                Text('Tìm kiếm',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon:
                const Icon(Icons.add, color: Colors.white),
            onSelected: (value) {
              if (value == 'group') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const CreateGroupScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'group',
                child: Row(
                  children: [
                    Icon(Icons.group_add,
                        color: Color(0xFF0068FF)),
                    SizedBox(width: 10),
                    Text('Tạo nhóm'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'friend',
                child: Row(
                  children: [
                    Icon(Icons.person_add,
                        color: Color(0xFF0068FF)),
                    SizedBox(width: 10),
                    Text('Thêm bạn (Qua Tìm kiếm)'),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants',
                arrayContains: currentUserId)
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
                'Chưa có cuộc trò chuyện nào.\nHãy tìm kiếm bạn bè để chat!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Lấy danh sách các tài liệu chat
          List<DocumentSnapshot> chatDocs =
              List.from(snapshot.data!.docs);

          // TỰ SẮP XẾP BẰNG DART (Client-side sorting): Đẩy tin nhắn mới nhất lên đầu
          chatDocs.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            Timestamp? aTime =
                aData['lastMessageTime'] as Timestamp?;
            Timestamp? bTime =
                bData['lastMessageTime'] as Timestamp?;
            if (aTime == null) {
              return 1;
            }
            if (bTime == null) {
              return -1;
            }
            return bTime
                .compareTo(aTime); // Sắp xếp giảm dần
          });

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              var chatData = chatDocs[index].data()
                  as Map<String, dynamic>;
              String chatId = chatDocs[index].id;
              bool isGroup = chatData['isGroup'] ?? false;
              String lastMsg = chatData['lastMessage'] ??
                  'Chưa có tin nhắn';
              String timeStr = _formatTimestamp(
                  chatData['lastMessageTime']
                      as Timestamp?);

              // ---------------------------------------------------------------
              // TRƯỜNG HỢP 1: NẾU LÀ CHAT NHÓM (GROUP) -> ĐIỀU HƯỚNG SANG GROUP CHAT
              // ---------------------------------------------------------------
              if (isGroup) {
                String groupName = chatData['groupName'] ??
                    'Nhóm chưa đặt tên';
                return ListTile(
                  leading: const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.group,
                        color: Color(0xFF0068FF), size: 28),
                  ),
                  title: Text(groupName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  subtitle: Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(timeStr,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(
                          chatId: chatId,
                          groupName: groupName,
                        ),
                      ),
                    );
                  },
                );
              }

              // ---------------------------------------------------------------
              // TRƯỜNG HỢP 2: NẾU LÀ CHAT ĐƠN 2 NGƯỜI
              // ---------------------------------------------------------------
              List<dynamic> participants =
                  chatData['participants'] ?? [];
              String receiverId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (receiverId.isEmpty) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(receiverId)
                    .get(),
                builder: (context, userSnapshot) {
                  String title = 'Người dùng';
                  String avatarUrl = '';

                  if (userSnapshot.hasData &&
                      userSnapshot.data!.exists) {
                    var userData = userSnapshot.data!.data()
                        as Map<String, dynamic>;
                    title = userData['displayName'] ??
                        'Người dùng';
                    avatarUrl = userData['photoUrl'] ?? '';
                  }

                  bool isNewChat =
                      lastMsg == 'Bắt đầu cuộc trò chuyện';

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 0.5)),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.blue[100],
                        backgroundImage:
                            avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                title.isNotEmpty
                                    ? title[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black)),
                      subtitle: Padding(
                        padding:
                            const EdgeInsets.only(top: 4.0),
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isNewChat
                                ? FontWeight.w500
                                : FontWeight.normal,
                            color: isNewChat
                                ? const Color(0xFF0068FF)
                                : const Color.fromARGB(
                                    255, 74, 74, 74),
                          ),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(timeStr,
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12)),
                          const SizedBox(height: 5),
                          if (!isNewChat)
                            Container(
                              width: 8,
                              height: 8,
                              decoration:
                                  const BoxDecoration(
                                      color:
                                          Color(0xFF0068FF),
                                      shape:
                                          BoxShape.circle),
                            ),
                        ],
                      ),
                      onTap: () {
                        //Truyền thêm thuộc tính receiverId vào ChatScreen để ChatScreen có thể sử dụng cho các tính năng như ghim tin nhắn, thu hồi tin nhắn, v.v.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              currentUserId: currentUserId,
                              receiverName: title,
                              receiverId: receiverId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
