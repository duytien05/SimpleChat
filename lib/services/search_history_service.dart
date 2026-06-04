import 'package:cloud_firestore/cloud_firestore.dart';

class SearchHistoryService {
  // Thêm từ khóa vào lịch sử tìm kiếm gần đây
  static Future<void> saveSearchQuery({
    required String currentUserId,
    required String query,
  }) async {
    if (query.isEmpty) return;

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('recent_queries');

    // Nếu từ khóa đã tồn tại trước đó, xóa đi để đưa lên đầu danh sách
    final existing = await historyRef.doc(query).get();
    if (existing.exists) {
      await historyRef.doc(query).delete();
    }

    // Lưu từ khóa mới kèm thời gian tìm kiếm
    await historyRef.doc(query).set({
      'query': query,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Thêm liên hệ vào danh sách đã truy cập gần đây (Khi click vào kết quả hoặc chat)
  static Future<void> saveRecentContact({
    required String currentUserId,
    required String targetUid,
    required String displayName,
    required String photoUrl,
  }) async {
    final contactRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('recent_contacts');

    // Xóa bản ghi cũ nếu trùng để cập nhật vị trí lên đầu
    final existing = await contactRef.doc(targetUid).get();
    if (existing.exists) {
      await contactRef.doc(targetUid).delete();
    }

    await contactRef.doc(targetUid).set({
      'uid': targetUid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Xóa một từ khóa cụ thể khỏi lịch sử
  static Future<void> deleteQuery(
      String currentUserId, String query) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('recent_queries')
        .doc(query)
        .delete();
  }

  // Xóa toàn bộ lịch sử từ khóa
  static Future<void> clearAllQueries(
      String currentUserId) async {
    final snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('recent_queries')
        .get();

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }
}
