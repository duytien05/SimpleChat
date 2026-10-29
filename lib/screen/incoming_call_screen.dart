import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'active_call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callId;
  final String chatId;
  final String callerId;
  final String callerDisplayName;
  final String callerPhotoUrl;
  final bool hasVideo;

  const IncomingCallScreen({
    Key? key,
    required this.callId,
    required this.chatId,
    required this.callerId,
    required this.callerDisplayName,
    required this.callerPhotoUrl,
    required this.hasVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CallService callService = CallService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: callerPhotoUrl.isNotEmpty
                      ? NetworkImage(callerPhotoUrl)
                      : null,
                  child: callerPhotoUrl.isEmpty
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(callerDisplayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    hasVideo
                        ? 'Cuộc gọi Video đến...'
                        : 'Cuộc gọi thoại đến...',
                    style: const TextStyle(
                        color: Colors.grey)),
              ],
            ),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'rejectBtn',
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    await callService.rejectCall(
                        callId, chatId, callerId, hasVideo);
                    if (context.mounted)
                      Navigator.pop(context);
                  },
                  child: const Icon(Icons.call_end,
                      color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: 'acceptBtn',
                  backgroundColor: Colors.green,
                  onPressed: () async {
                    await callService.acceptCall(callId);
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActiveCallScreen(
                            callId: callId,
                            chatId: chatId,
                            callerId: callerId,
                            callerDisplayName:
                                callerDisplayName,
                            callerPhotoUrl: callerPhotoUrl,
                            hasVideo: hasVideo,
                            isCaller: false,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.call,
                      color: Colors.white),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
