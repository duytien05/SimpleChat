import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupInfoScreen extends StatelessWidget {
  final String chatId;
  const GroupInfoScreen({super.key, required this.chatId});

  void _showPublicProfile(
      BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue[100],
              backgroundImage:
                  userData['photoUrl'] != null &&
                          userData['photoUrl']
                              .toString()
                              .isNotEmpty
                      ? NetworkImage(userData['photoUrl'])
                      : null,
              child: userData['photoUrl'] == null
                  ? Text(
                      (userData['displayName'] ?? 'U')[0]
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 28))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(userData['displayName'] ?? 'Người dùng',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                'Email: ${userData['email'] ?? 'Không công khai'}',
                style: TextStyle(color: Colors.grey[600])),
            Text(
                'Số điện thoại: ${userData['phone'] ?? 'Không công khai'}',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng',
                  style: TextStyle(
                      color: Color(0xFF0068FF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData ||
            !chatSnapshot.data!.exists) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator()));
        }

        var chatData = chatSnapshot.data!.data()
            as Map<String, dynamic>;
        String groupName =
            chatData['groupName'] ?? 'Cài đặt nhóm';
        String adminId = chatData['adminId'] ?? '';
        List<dynamic> participants =
            chatData['participants'] ?? [];
        bool isAmIAdmin = (currentUserId == adminId);

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: const Color(0xFF0068FF),
            iconTheme:
                const IconThemeData(color: Colors.white),
            title: Text('Cài đặt nhóm: $groupName',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'DANH SÁCH THÀNH VIÊN (${participants.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('uid', whereIn: participants)
                      .snapshots(),
                  builder: (context, usersSnapshot) {
                    if (!usersSnapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator());
                    }

                    var userDocs = usersSnapshot.data!.docs;

                    return ListView.builder(
                      itemCount: userDocs.length,
                      itemBuilder: (context, index) {
                        var userData = userDocs[index]
                            .data() as Map<String, dynamic>;
                        String memberId = userData['uid'];
                        String name =
                            userData['displayName'] ??
                                'Người dùng';
                        String avatarUrl =
                            userData['photoUrl'] ?? '';
                        bool isMemberAdmin =
                            (memberId == adminId);

                        return Container(
                          color: Colors.white,
                          margin: const EdgeInsets.only(
                              bottom: 1),
                          child: ListTile(
                            onTap: () => _showPublicProfile(
                                context, userData),
                            leading: CircleAvatar(
                              backgroundImage: avatarUrl
                                      .isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? Text(
                                      name[0].toUpperCase())
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600)),
                                const SizedBox(width: 6),
                                if (isMemberAdmin) ...[
                                  const Icon(Icons.star,
                                      color: Colors.amber,
                                      size: 18)
                                ],
                              ],
                            ),
                            subtitle: Text(isMemberAdmin
                                ? 'Quản trị viên nhóm'
                                : 'Thành viên'),
                            trailing: isAmIAdmin &&
                                    memberId !=
                                        currentUserId
                                ? PopupMenuButton<String>(
                                    icon: const Icon(
                                        Icons.more_vert),
                                    onSelected:
                                        (value) async {
                                      if (value ==
                                          'remove') {
                                        await FirebaseFirestore
                                            .instance
                                            .collection(
                                                'chats')
                                            .doc(chatId)
                                            .update({
                                          'participants':
                                              FieldValue
                                                  .arrayRemove([
                                            memberId
                                          ])
                                        });
                                      } else if (value ==
                                          'transfer') {
                                        await FirebaseFirestore
                                            .instance
                                            .collection(
                                                'chats')
                                            .doc(chatId)
                                            .update({
                                          'adminId':
                                              memberId
                                        });
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                      const PopupMenuItem(
                                          value: 'transfer',
                                          child: Row(
                                              children: [
                                                Icon(
                                                    Icons
                                                        .star_border,
                                                    color: Colors
                                                        .amber),
                                                SizedBox(
                                                    width:
                                                        8),
                                                Text(
                                                    'Chuyển quyền Admin')
                                              ])),
                                      const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                              children: [
                                                Icon(
                                                    Icons
                                                        .person_remove,
                                                    color: Colors
                                                        .red),
                                                SizedBox(
                                                    width:
                                                        8),
                                                Text(
                                                    'Xóa khỏi nhóm',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.red))
                                              ])),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    elevation: 0,
                    side:
                        BorderSide(color: Colors.red[200]!),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12),
                  ),
                  icon: const Icon(Icons.exit_to_app,
                      color: Colors.red),
                  label: const Text('Rời khỏi nhóm',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  onPressed: () async {
                    if (isAmIAdmin &&
                        participants.length > 1) {
                      String nextAdmin =
                          participants.firstWhere(
                              (id) => id != currentUserId);
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .update({'adminId': nextAdmin});
                    }

                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .update({
                      'participants':
                          FieldValue.arrayRemove(
                              [currentUserId])
                    });

                    if (context.mounted) {
                      Navigator.of(context)
                        ..pop()
                        ..pop();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
