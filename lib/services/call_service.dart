import 'package:cloud_firestore/cloud_firestore.dart';

class CallService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<String> makeCall({
    required String chatId,
    required String callerId,
    required String callerDisplayName,
    required String callerPhotoUrl,
    required List<String> receiverIds,
    required String receiverDisplayName,
    required String receiverPhotoUrl,
    required bool hasVideo,
    required bool isGroup,
  }) async {
    String callId = _firestore.collection('calls').doc().id;

    await _firestore.collection('calls').doc(callId).set({
      'callId': callId,
      'chatId': chatId,
      'callerId': callerId,
      'callerDisplayName': callerDisplayName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverIds': receiverIds,
      'receiverDisplayName': receiverDisplayName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'hasVideo': hasVideo,
      'isGroup': isGroup,
      'status': 'ringing',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return callId;
  }

  Future<void> acceptCall(String callId) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .update({'status': 'accepted'});
  }

  Future<void> rejectCall(String callId, String chatId,
      String callerId, bool hasVideo) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .update({'status': 'rejected'});
    await saveCallLog(
      chatId: chatId,
      senderId: callerId,
      durationInSeconds: 0,
      callStatus: 'declined',
      hasVideo: hasVideo,
    );
  }

  Future<void> endCall({
    required String callId,
    required String chatId,
    required String callerId,
    required int durationInSeconds,
    required bool hasVideo,
  }) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .update({'status': 'ended'});
    await saveCallLog(
      chatId: chatId,
      senderId: callerId,
      durationInSeconds: durationInSeconds,
      callStatus:
          durationInSeconds > 0 ? 'completed' : 'missed',
      hasVideo: hasVideo,
    );
  }

  Future<void> saveCallLog({
    required String chatId,
    required String senderId,
    required int durationInSeconds,
    required String callStatus,
    required bool hasVideo,
  }) async {
    String logContent =
        hasVideo ? 'Cuộc gọi Video' : 'Cuộc gọi thoại';

    if (callStatus == 'declined') {
      logContent = 'Cuộc gọi bị từ chối';
    } else if (callStatus == 'missed') {
      logContent = 'Cuộc gọi nhỡ';
    } else {
      int mins = durationInSeconds ~/ 60;
      int secs = durationInSeconds % 60;
      String timeFormatted =
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      logContent = '$logContent — $timeFormatted';
    }

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'content': logContent,
      'type': 'call_log',
      'callDuration': durationInSeconds,
      'callStatus': callStatus,
      'hasVideo': hasVideo,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({
      'lastMessage': logContent,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}
