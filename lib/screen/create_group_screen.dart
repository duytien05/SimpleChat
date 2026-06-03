import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() =>
      _CreateGroupScreenState();
}

class _CreateGroupScreenState
    extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController =
      TextEditingController();
  final List<String> _selectedMemberIds = [];
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0068FF),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Tạo nhóm mới',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Khối nhập tên nhóm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Nhập tên nhóm',
                labelStyle: const TextStyle(
                    color: Color(0xFF0068FF)),
                prefixIcon: const Icon(Icons.group_add,
                    color: Color(0xFF0068FF)),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                      color: Color(0xFF0068FF), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('GỢI Ý TỪ DANH SÁCH BẠN BÈ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13)),
            ),
          ),
          const Divider(),

          // Đọc danh sách bạn bè realtime để hiển thị đề xuất mời vào nhóm
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData ||
                    !userSnapshot.data!.exists) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                var myData = userSnapshot.data!.data()
                    as Map<String, dynamic>;
                List<dynamic> friendsList =
                    myData['friends'] ?? [];

                if (friendsList.isEmpty) {
                  return const Center(
                    child: Text(
                        'Bạn cần có bạn bè trong danh bạ trước khi tạo nhóm.',
                        style:
                            TextStyle(color: Colors.grey)),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('uid', whereIn: friendsList)
                      .snapshots(),
                  builder: (context, friendsSnapshot) {
                    if (!friendsSnapshot.hasData)
                      return const SizedBox.shrink();

                    var friendsDocs =
                        friendsSnapshot.data!.docs;

                    return ListView.builder(
                      itemCount: friendsDocs.length,
                      itemBuilder: (context, index) {
                        var friendData = friendsDocs[index]
                            .data() as Map<String, dynamic>;
                        String uid = friendData['uid'];
                        String name =
                            friendData['displayName'] ??
                                'Người dùng';
                        String avatarUrl =
                            friendData['photoUrl'] ?? '';
                        bool isChecked = _selectedMemberIds
                            .contains(uid);

                        return CheckboxListTile(
                          activeColor:
                              const Color(0xFF0068FF),
                          value: isChecked,
                          title: Text(name,
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600)),
                          secondary: CircleAvatar(
                            backgroundImage: avatarUrl
                                    .isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? Text(
                                    name[0].toUpperCase())
                                : null,
                          ),
                          onChanged: (bool? val) {
                            setState(() {
                              if (val == true) {
                                _selectedMemberIds.add(uid);
                              } else {
                                _selectedMemberIds
                                    .remove(uid);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Nút bấm tiến hành tạo nhóm hành động
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0068FF),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(25)),
                ),
                onPressed: _isCreating ||
                        _selectedMemberIds.isEmpty
                    ? null
                    : () async {
                        String groupName =
                            _groupNameController.text
                                .trim();
                        if (groupName.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Vui lòng nhập tên nhóm!')));
                          return;
                        }

                        setState(() => _isCreating = true);

                        // Mảng thành viên bao gồm cả chính mình (người tạo)
                        List<String> participants = [
                          currentUserId,
                          ..._selectedMemberIds
                        ];

                        // Lưu tài liệu nhóm mới lên Firestore
                        await FirebaseFirestore.instance
                            .collection('chats')
                            .add({
                          'isGroup': true,
                          'groupName': groupName,
                          'participants': participants,
                          'adminId':
                              currentUserId, // Ai tạo nhóm đầu tiên thì làm Quản trị viên
                          'lastMessage':
                              'Nhóm vừa được tạo thành công!',
                          'lastMessageTime':
                              FieldValue.serverTimestamp(),
                        });

                        Navigator.pop(
                            context); // Quay về sau khi tạo xong
                      },
                child: _isCreating
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text('Tạo nhóm ngay',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
