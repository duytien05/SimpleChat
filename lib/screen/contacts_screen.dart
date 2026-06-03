import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'group_chat_screen.dart'; // Đã import thêm màn hình chat nhóm vào đây

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF0068FF),
          elevation: 0,
          title: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SearchScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.search,
                      color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Text('Tìm bạn bè...',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16)),
                ],
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "BẠN BÈ"),
              Tab(text: "NHÓM"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FriendsTab(),
            GroupsTab(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 1: DANH SÁCH BẠN BÈ & LỜI MỜI KẾT BẠN CHỜ DUYỆT
// =============================================================================
class FriendsTab extends StatelessWidget {
  const FriendsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    return ListView(
      children: [
        // ---------- WIDGET LỜI MỜI KẾT BẠN (NHẬN ĐƯỢC) TỪ NGƯỜI KHÁC ----------
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('friend_requests')
              .where('receiverId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, requestSnapshot) {
            if (!requestSnapshot.hasData ||
                requestSnapshot.data!.docs.isEmpty) {
              return const SizedBox
                  .shrink(); // Ẩn hoàn toàn nếu không có lời mời nào
            }

            var requestDocs = requestSnapshot.data!.docs;

            return Container(
              color: Colors.amber[50],
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.person_add_alt_1,
                    color: Colors.orange, size: 28),
                title: Text(
                  'Lời mời kết bạn chờ duyệt (${requestDocs.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
                children: requestDocs.map((doc) {
                  var reqData =
                      doc.data() as Map<String, dynamic>;
                  String senderId = reqData['senderId'];

                  // Lấy thông tin chi tiết người gửi lời mời
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(senderId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData ||
                          !userSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      var userData = userSnapshot.data!
                          .data() as Map<String, dynamic>;
                      String name =
                          userData['displayName'] ??
                              'Người dùng';
                      String avatarUrl =
                          userData['photoUrl'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                          child: avatarUrl.isEmpty
                              ? Text(name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600)),
                        subtitle: const Text(
                            'Muốn kết bạn với bạn'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // NÚT ĐỒNG Ý (V)
                            IconButton(
                              icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 32),
                              onPressed: () async {
                                await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .doc(currentUserId)
                                    .update({
                                  'friends':
                                      FieldValue.arrayUnion(
                                          [senderId])
                                });
                                await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .doc(senderId)
                                    .update({
                                  'friends':
                                      FieldValue.arrayUnion(
                                          [currentUserId])
                                });

                                String chatId = currentUserId
                                            .hashCode <=
                                        senderId.hashCode
                                    ? '${currentUserId}_$senderId'
                                    : '${senderId}_$currentUserId';

                                await FirebaseFirestore
                                    .instance
                                    .collection('chats')
                                    .doc(chatId)
                                    .set({
                                  'isGroup': false,
                                  'participants': [
                                    currentUserId,
                                    senderId
                                  ],
                                  'lastMessage':
                                      'Các bạn đã trở thành bạn bè! Hãy gửi lời chào.',
                                  'lastMessageTime':
                                      FieldValue
                                          .serverTimestamp(),
                                }, SetOptions(merge: true));

                                await doc.reference
                                    .delete();
                              },
                            ),
                            // NÚT TỪ CHỐI (X)
                            IconButton(
                              icon: const Icon(Icons.cancel,
                                  color: Colors.red,
                                  size: 32),
                              onPressed: () async {
                                await doc.reference
                                    .delete();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),

        // ---------- DANH SÁCH BẠN BÈ ĐÃ KẾT BẠN THÀNH CÔNG THỰC TẾ ----------
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData ||
                !userSnapshot.data!.exists) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()));
            }

            var myData = userSnapshot.data!.data()
                as Map<String, dynamic>;
            List<dynamic> friendsList =
                myData['friends'] ?? [];

            if (friendsList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 70,
                          color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      const Text("Danh bạ trống",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('uid', whereIn: friendsList)
                  .snapshots(),
              builder: (context, friendsSnapshot) {
                if (!friendsSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                var docs = friendsSnapshot.data!.docs;
                List<Map<String, dynamic>> sortedFriends =
                    docs
                        .map((doc) => doc.data()
                            as Map<String, dynamic>)
                        .toList();
                sortedFriends.sort((a, b) =>
                    (a['displayName'] ?? '')
                        .toString()
                        .compareTo((b['displayName'] ?? '')
                            .toString()));

                List<dynamic> listWithHeaders = [];
                String lastChar = "";
                for (var friend in sortedFriends) {
                  String name =
                      friend['displayName'] ?? 'Người dùng';
                  String firstChar = name.isNotEmpty
                      ? name[0].toUpperCase()
                      : '#';
                  if (firstChar != lastChar) {
                    listWithHeaders.add(firstChar);
                    lastChar = firstChar;
                  }
                  listWithHeaders.add(friend);
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: listWithHeaders.length,
                  itemBuilder: (context, index) {
                    var item = listWithHeaders[index];

                    if (item is String) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        color: Colors.grey[200],
                        child: Text(item,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
                      );
                    }

                    var friendData =
                        item as Map<String, dynamic>;
                    String title =
                        friendData['displayName'] ??
                            'Người dùng';
                    String avatarUrl =
                        friendData['photoUrl'] ?? '';
                    String targetUid =
                        friendData['uid'] ?? '';

                    return Container(
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                          child: avatarUrl.isEmpty
                              ? Text(title[0].toUpperCase())
                              : null,
                        ),
                        title: Text(title,
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600)),
                        trailing: const Icon(Icons.chat,
                            color: Color(0xFF0068FF)),
                        onTap: () {
                          String chatId = currentUserId
                                      .hashCode <=
                                  targetUid.hashCode
                              ? '${currentUserId}_$targetUid'
                              : '${targetUid}_$currentUserId';

                          //Bổ sung thuộc tính receiverId lấy từ dữ liệu đối phương (targetUid)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chatId,
                                currentUserId:
                                    currentUserId,
                                receiverName: title,
                                receiverId: targetUid,
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
      ],
    );
  }
}

// =============================================================================
// TAB 2: DANH SÁCH CÁC NHÓM CHAT (GROUPS)
// =============================================================================
class GroupsTab extends StatelessWidget {
  const GroupsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('isGroup', isEqualTo: true)
          .where('participants',
              arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }
        var groupDocs = snapshot.data!.docs;

        if (groupDocs.isEmpty) {
          return Center(
            child: Text("Chưa tham gia nhóm nào",
                style: TextStyle(
                    color: Colors.grey[400], fontSize: 16)),
          );
        }

        return ListView.builder(
          itemCount: groupDocs.length,
          itemBuilder: (context, index) {
            var groupData = groupDocs[index].data()
                as Map<String, dynamic>;
            String groupName = groupData['groupName'] ??
                'Nhóm chưa đặt tên';
            String chatId = groupDocs[index].id;
            int totalMembers =
                (groupData['participants'] as List).length;

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.group,
                    color: Color(0xFF0068FF)),
              ),
              title: Text(groupName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600)),
              subtitle: Text('$totalMembers thành viên'),
              onTap: () {
                // ĐÃ FIX & ĐỒNG BỘ: Chuyển hướng về GroupChatScreen thay vì ChatScreen
                // giúp cấu trúc code đồng nhất với chat_list_screen và không bị lỗi thiếu receiverId.
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
          },
        );
      },
    );
  }
}
