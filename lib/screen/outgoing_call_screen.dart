import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/call_service.dart';
import 'active_call_screen.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String callId;
  final String chatId;
  final String callerId;
  final String receiverDisplayName;
  final String receiverPhotoUrl;
  final bool hasVideo;

  const OutgoingCallScreen({
    Key? key,
    required this.callId,
    required this.chatId,
    required this.callerId,
    required this.receiverDisplayName,
    required this.receiverPhotoUrl,
    required this.hasVideo,
  }) : super(key: key);

  @override
  State<OutgoingCallScreen> createState() =>
      _OutgoingCallScreenState();
}

class _OutgoingCallScreenState
    extends State<OutgoingCallScreen> {
  StreamSubscription<DocumentSnapshot>? _callSubscription;
  final CallService _callService = CallService();

  @override
  void initState() {
    super.initState();
    _listenCallState();
  }

  void _listenCallState() {
    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        String status = snapshot.data()?['status'] ?? '';

        if (status == 'accepted') {
          _callSubscription?.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveCallScreen(
                  callId: widget.callId,
                  chatId: widget.chatId,
                  callerId: widget.callerId,
                  callerDisplayName:
                      widget.receiverDisplayName,
                  callerPhotoUrl: widget.receiverPhotoUrl,
                  hasVideo: widget.hasVideo,
                  isCaller: true,
                ),
              ),
            );
          }
        } else if (status == 'rejected' ||
            status == 'ended') {
          _closeScreen();
        }
      }
    });
  }

  void _closeScreen() {
    _callSubscription?.cancel();
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.blueGrey,
                    backgroundImage:
                        widget.receiverPhotoUrl.isNotEmpty
                            ? NetworkImage(
                                widget.receiverPhotoUrl)
                            : null,
                    child: widget.receiverPhotoUrl.isEmpty
                        ? const Icon(Icons.person,
                            size: 65, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.receiverDisplayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đang đổ chuông...',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
              FloatingActionButton(
                heroTag: 'cancelCallBtn',
                backgroundColor: Colors.redAccent,
                onPressed: () async {
                  await _callService.endCall(
                    callId: widget.callId,
                    chatId: widget.chatId,
                    callerId: widget.callerId,
                    durationInSeconds: 0,
                    hasVideo: widget.hasVideo,
                  );
                  _closeScreen();
                },
                child: const Icon(Icons.call_end,
                    color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
