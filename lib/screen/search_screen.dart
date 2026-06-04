import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // Hỗ trợ giải mã ảnh đại diện chuỗi Base64 trên Web
import '../services/search_history_service.dart';
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
  bool _hasSearched = false;

  // Hàm helper để parse dữ liệu Avatar dạng Base64 hoặc Network Link
  ImageProvider? _parseAvatar(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64String = photoUrl.split(',')[1];
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(photoUrl);
  }

  void _searchUsers() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults.clear();
    });

    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    // Lưu từ khóa tìm kiếm vào lịch sử qua Service
    await SearchHistoryService.saveSearchQuery(
      currentUserId: currentUserId,
      query: query,
    );

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
          onChanged: (val) {
            if (val.trim().isEmpty) {
              setState(() {
                _hasSearched = false;
                _searchResults.clear();
              });
            }
          },
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
          : _hasSearched
              ? _buildSearchResults(currentUserId)
              : _buildHistoryDashboard(currentUserId),
    );
  }

  // GIAO DIỆN LỊCH SỬ KHI CHƯA GÕ TÌM KIẾM (KHÁM PHÁ / GẦN ĐÂY)
  Widget _buildHistoryDashboard(String currentUserId) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LIÊN HỆ ĐÃ TÌM GẦN ĐÂY (VÒNG TRÒN TRƯỢT NGANG)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .collection('recent_contacts')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              var docs = snapshot.data!.docs;

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                        left: 16.0,
                        top: 16.0,
                        bottom: 12.0),
                    child: Text(
                      'Liên hệ gần đây',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var contact = docs[index].data()
                            as Map<String, dynamic>;
                        String name =
                            contact['displayName'] ??
                                'User';
                        String photoUrl =
                            contact['photoUrl'] ?? '';
                        String targetUid =
                            contact['uid'] ?? '';
                        final avatarImg =
                            _parseAvatar(photoUrl);

                        return GestureDetector(
                          onTap: () => _navigateToChat(
                              context,
                              currentUserId,
                              targetUid,
                              name),
                          child: Container(
                            width: 75,
                            margin:
                                const EdgeInsets.symmetric(
                                    horizontal: 4),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor:
                                      const Color(
                                          0xFF0068FF),
                                  backgroundImage:
                                      avatarImg,
                                  child: avatarImg == null
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                              color: Colors
                                                  .white,
                                              fontWeight:
                                                  FontWeight
                                                      .bold))
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  textAlign:
                                      TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(
                      thickness: 4,
                      color: Color(0xFFF4F5F7)),
                ],
              );
            },
          ),

          // 2. TỪ KHÓA ĐÃ TÌM GẦN ĐÂY
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .collection('recent_queries')
                .orderBy('timestamp', descending: true)
                .limit(15)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'Nhập thông tin để tìm kiếm bạn bè',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 15),
                    ),
                  ),
                );
              }

              var docs = snapshot.data!.docs;

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Từ khóa đã tìm',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        GestureDetector(
                          onTap: () => SearchHistoryService
                              .clearAllQueries(
                                  currentUserId),
                          child: const Text(
                            'Xóa lịch sử',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      String queryText = docs[index].id;

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.search,
                            color: Colors.grey, size: 20),
                        title: Text(queryText,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close,
                              size: 16, color: Colors.grey),
                          onPressed: () =>
                              SearchHistoryService
                                  .deleteQuery(
                                      currentUserId,
                                      queryText),
                        ),
                        onTap: () {
                          _searchController.text =
                              queryText;
                          _searchUsers();
                        },
                      );
                    },
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  // GIAO DIỆN HIỂN THỊ KẾT QUẢ TÌM KIẾM
  Widget _buildSearchResults(String currentUserId) {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy người dùng phù hợp',
          style:
              TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        var userData = _searchResults[index];
        String targetUid = userData['uid'];
        String name =
            userData['displayName'] ?? 'Người dùng';
        String avatarUrl = userData['photoUrl'] ?? '';
        final avatarImg = _parseAvatar(avatarUrl);

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData)
              return const SizedBox.shrink();

            var myData = userSnapshot.data!.data()
                as Map<String, dynamic>;
            List<dynamic> myFriends =
                myData['friends'] ?? [];

            // Thiết lập hàm xử lý khi nhấn vào liên hệ
            void handleContactTap() async {
              await SearchHistoryService.saveRecentContact(
                currentUserId: currentUserId,
                targetUid: targetUid,
                displayName: name,
                photoUrl: avatarUrl,
              );
              if (!mounted) return;
              _navigateToChat(
                  context, currentUserId, targetUid, name);
            }

            if (myFriends.contains(targetUid)) {
              return ListTile(
                onTap: handleContactTap,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0068FF),
                  backgroundImage: avatarImg,
                  child: avatarImg == null
                      ? Text(name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white))
                      : null,
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                subtitle: Text(
                    userData['phone'] ?? userData['email']),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.chat,
                      size: 16, color: Colors.white),
                  label: const Text('Nhắn tin',
                      style:
                          TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF0068FF)),
                  onPressed: handleContactTap,
                ),
              );
            }

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('friend_requests')
                  .doc('${currentUserId}_$targetUid')
                  .snapshots(),
              builder: (context, requestSnapshot) {
                bool hasSentRequest =
                    requestSnapshot.hasData &&
                        requestSnapshot.data!.exists;

                return ListTile(
                  onTap: handleContactTap,
                  leading: CircleAvatar(
                    backgroundColor:
                        const Color(0xFF0068FF),
                    backgroundImage: avatarImg,
                    child: avatarImg == null
                        ? Text(name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white))
                        : null,
                  ),
                  title: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(userData['phone'] ??
                      userData['email']),
                  trailing: hasSentRequest
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.grey)),
                          child: const Text(
                              'Đã gửi lời mời',
                              style: TextStyle(
                                  color: Colors.grey)),
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.person_add,
                              size: 16,
                              color: Colors.white),
                          label: const Text('Kết bạn',
                              style: TextStyle(
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF0068FF)),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection(
                                    'friend_requests')
                                .doc(
                                    '${currentUserId}_$targetUid')
                                .set({
                              'senderId': currentUserId,
                              'receiverId': targetUid,
                              'timestamp': FieldValue
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
          receiverId: targetUid,
        ),
      ),
    );
  }
}
