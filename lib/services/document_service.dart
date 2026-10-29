import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> shareMessageDocToPublicHub({
    required String messageId,
    required String chatId,
    required String title,
    required String description,
    required String category,
    required String fileUrl,
    required String fileType,
    required String fileSize,
    required String uploadedBy,
    required String uploaderName,
    required String uploaderPhoto,
  }) async {
    String docId =
        _firestore.collection('documents').doc().id;
    await _firestore
        .collection('documents')
        .doc(docId)
        .set({
      'docId': docId,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'category': category,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'uploaderPhoto': uploaderPhoto,
      'sourceChatId': chatId,
      'isPublic': true,
      'downloadCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isSharedToHub': true});
  }

  Stream<List<Map<String, dynamic>>> getPublicDocuments(
      {String? category}) {
    Query query = _firestore
        .collection('documents')
        .where('isPublic', isEqualTo: true);

    if (category != null &&
        category.isNotEmpty &&
        category != 'Tất cả') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      List<Map<String, dynamic>> docs = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      docs.sort((a, b) {
        Timestamp? aTime = a['createdAt'] as Timestamp?;
        Timestamp? bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return docs;
    });
  }

  Future<void> incrementDownloadCount(String docId) async {
    await _firestore
        .collection('documents')
        .doc(docId)
        .update({
      'downloadCount': FieldValue.increment(1),
    });
  }
}
