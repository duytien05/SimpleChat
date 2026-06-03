import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController =
      TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  void _searchUsers() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    // Tìm kiếm song song theo cả email hoặc số điện thoại
    var emailQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: query)
        .get();

    var phoneQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: query)
        .get();

    List<Map<String, dynamic>> tempResults = [];

    for (var doc in [
      ...emailQuery.docs,
      ...phoneQuery.docs
    ]) {
      var data = doc.data();
      // Loại bỏ chính mình khỏi danh sách tìm kiếm
      if (data['uid'] != currentUserId) {
        if (!tempResults.any(
            (element) => element['uid'] == data['uid'])) {
          tempResults.add(data);
        }
      }
    }

    setState(() {
      _searchResults = tempResults;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0068FF),
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(
              color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText:
                'Tìm kiếm qua email hoặc số điện thoại...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _searchUsers(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search,
                color: Colors.white),
            onPressed: _searchUsers,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Nhập thông tin để tìm kiếm bạn bè'
                        : 'Không tìm thấy người dùng phù hợp',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    var userData = _searchResults[index];
                    String targetUid = userData['uid'];
                    String name = userData['displayName'] ??
                        'Người dùng';
                    String avatarUrl =
                        userData['photoUrl'] ?? '';

                    // Lắng nghe dữ liệu mối quan hệ Realtime bằng StreamBuilder
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUserId)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData)
                          return const SizedBox.shrink();

                        var myData = userSnapshot.data!
                            .data() as Map<String, dynamic>;
                        List<dynamic> myFriends =
                            myData['friends'] ?? [];

                        // 1. Trạng thái: Đã là bạn bè
                        if (myFriends.contains(targetUid)) {
                          return ListTile(
                            onTap: () => _navigateToChat(
                              context,
                              currentUserId,
                              targetUid,
                              name,
                            ),
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
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold)),
                            subtitle: Text(
                                userData['phone'] ??
                                    userData['email']),
                            trailing: ElevatedButton.icon(
                              icon: const Icon(Icons.chat,
                                  size: 16,
                                  color: Colors.white),
                              label: const Text('Nhắn tin',
                                  style: TextStyle(
                                      color: Colors.white)),
                              style:
                                  ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(
                                              0xFF0068FF)),
                              onPressed: () =>
                                  _navigateToChat(
                                      context,
                                      currentUserId,
                                      targetUid,
                                      name),
                            ),
                          );
                        }

                        // 2. Kiểm tra xem mình đã gửi lời mời cho người này chưa
                        return StreamBuilder<
                            DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('friend_requests')
                              .doc(
                                  '${currentUserId}_$targetUid')
                              .snapshots(),
                          builder:
                              (context, requestSnapshot) {
                            bool hasSentRequest =
                                requestSnapshot.hasData &&
                                    requestSnapshot
                                        .data!.exists;

                            return ListTile(
                              onTap: () => _navigateToChat(
                                context,
                                currentUserId,
                                targetUid,
                                name,
                              ),
                              leading: CircleAvatar(
                                backgroundImage:
                                    avatarUrl.isNotEmpty
                                        ? NetworkImage(
                                            avatarUrl)
                                        : null,
                                child: avatarUrl.isEmpty
                                    ? Text(name[0]
                                        .toUpperCase())
                                    : null,
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold)),
                              subtitle: Text(
                                  userData['phone'] ??
                                      userData['email']),
                              trailing: hasSentRequest
                                  ? OutlinedButton(
                                      onPressed: null,
                                      style: OutlinedButton
                                          .styleFrom(
                                              side: const BorderSide(
                                                  color: Colors
                                                      .grey)),
                                      child: const Text(
                                          'Đã gửi lời mời',
                                          style: TextStyle(
                                              color: Colors
                                                  .grey)),
                                    )
                                  : ElevatedButton.icon(
                                      icon: const Icon(
                                          Icons.person_add,
                                          size: 16,
                                          color:
                                              Colors.white),
                                      label: const Text(
                                          'Kết bạn',
                                          style: TextStyle(
                                              color: Colors
                                                  .white)),
                                      style: ElevatedButton
                                          .styleFrom(
                                              backgroundColor:
                                                  const Color(
                                                      0xFF0068FF)),
                                      onPressed: () async {
                                        await FirebaseFirestore
                                            .instance
                                            .collection(
                                                'friend_requests')
                                            .doc(
                                                '${currentUserId}_$targetUid')
                                            .set({
                                          'senderId':
                                              currentUserId,
                                          'receiverId':
                                              targetUid,
                                          'timestamp':
                                              FieldValue
                                                  .serverTimestamp(),
                                        });
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

  void _navigateToChat(
      BuildContext context,
      String currentUserId,
      String targetUid,
      String receiverName) {
    String chatId =
        currentUserId.hashCode <= targetUid.hashCode
            ? '${currentUserId}_$targetUid'
            : '${targetUid}_$currentUserId';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: currentUserId,
          receiverName: receiverName,
          receiverId:
              targetUid, // 👈 ĐÃ BỔ SUNG THAM SỐ NÀY ĐỂ FIX LỖI BUILD
        ),
      ),
    );
  }
}
