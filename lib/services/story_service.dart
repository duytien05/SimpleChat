import 'package:cloud_firestore/cloud_firestore.dart';

class StoryService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // 1. Hàm đăng khoảnh khắc mới
  static Future<void> uploadStory({
    required String userId,
    required String userName,
    required String userAvatar,
    required String imageBase64,
    required String caption,
  }) async {
    try {
      DateTime now = DateTime.now();
      DateTime expireTime = now.add(
          const Duration(hours: 24)); // Hết hạn sau 24h

      DocumentReference docRef =
          _firestore.collection('stories').doc();

      await docRef.set({
        'storyId': docRef.id,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'imageUrl':
            imageBase64, // Lưu chuỗi Base64 đã nén cực nhẹ
        'caption': caption,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expireTime),
      });
    } catch (e) {
      print("Lỗi khi thêm Story lên Firestore: $e");
    }
  }

  // 2. Stream lấy danh sách khoảnh khắc chưa quá 24h
  static Stream<QuerySnapshot> getActiveStories() {
    return _firestore
        .collection('stories')
        .where('expiresAt',
            isGreaterThan:
                Timestamp.fromDate(DateTime.now()))
        .snapshots();
  }
}
