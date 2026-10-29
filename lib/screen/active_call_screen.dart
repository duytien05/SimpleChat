import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/call_service.dart';

const String appId = "76c98c51f638477c81059b24529f134d";

class ActiveCallScreen extends StatefulWidget {
  final String callId;
  final String chatId;
  final String callerId;
  final String callerDisplayName;
  final String callerPhotoUrl;
  final bool hasVideo;
  final bool isCaller;

  const ActiveCallScreen({
    Key? key,
    required this.callId,
    required this.chatId,
    required this.callerId,
    required this.callerDisplayName,
    required this.callerPhotoUrl,
    required this.hasVideo,
    required this.isCaller,
  }) : super(key: key);

  @override
  State<ActiveCallScreen> createState() =>
      _ActiveCallScreenState();
}

class _ActiveCallScreenState
    extends State<ActiveCallScreen> {
  final CallService _callService = CallService();
  RtcEngine? _engine;

  bool _isJoined = false;
  int? _remoteUid;
  bool _isMuted = false;

  int _callDurationInSeconds = 0;
  Timer? _timer;
  StreamSubscription? _callStatusSub;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenCallStatus();
    _startTimer();
  }

  Future<void> _initAgora() async {
    try {
      if (!kIsWeb) {
        await [Permission.microphone, Permission.camera]
            .request();
      }

      RtcEngine engine = createAgoraRtcEngine();
      await engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile:
            ChannelProfileType.channelProfileCommunication,
      ));

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess:
              (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() {
                _isJoined = true;
              });
            }
          },
          onUserJoined: (RtcConnection connection,
              int remoteUid, int elapsed) {
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
              });
            }
          },
          onUserOffline: (RtcConnection connection,
              int remoteUid, UserOfflineReasonType reason) {
            _handleEndCall();
          },
        ),
      );

      if (widget.hasVideo && !kIsWeb) {
        await engine.enableVideo();
        await engine.startPreview();
      } else {
        await engine.enableAudio();
      }

      await engine.joinChannel(
        token: '',
        channelId: widget.chatId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType:
              ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType
              .channelProfileCommunication,
        ),
      );

      if (mounted) {
        setState(() {
          _engine = engine;
        });
      }
    } catch (e) {
      debugPrint("Cảnh báo RTC Web Engine: $e");
    }
  }

  void _listenCallStatus() {
    _callStatusSub = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        String status = snapshot.data()?['status'] ?? '';
        if (status == 'ended' || status == 'rejected') {
          _exitCallScreen();
        }
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationInSeconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleEndCall() async {
    _timer?.cancel();
    await _callService.endCall(
      callId: widget.callId,
      chatId: widget.chatId,
      callerId: widget.callerId,
      durationInSeconds: _callDurationInSeconds,
      hasVideo: widget.hasVideo,
    );
    await _exitCallScreen();
  }

  Future<void> _exitCallScreen() async {
    _timer?.cancel();
    _callStatusSub?.cancel();
    if (_engine != null) {
      try {
        await _engine!.leaveChannel();
        await _engine!.release();
      } catch (_) {}
    }
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callStatusSub?.cancel();
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            (widget.hasVideo &&
                    _remoteUid != null &&
                    !kIsWeb)
                ? _buildVideoViews()
                : _buildVoiceView(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                          _isMuted
                              ? Icons.mic_off
                              : Icons.mic,
                          color: Colors.white,
                          size: 30),
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                        });
                        _engine?.muteLocalAudioStream(
                            _isMuted);
                      },
                    ),
                    FloatingActionButton(
                      heroTag: 'exitCallBtn',
                      backgroundColor: Colors.redAccent,
                      onPressed: _handleEndCall,
                      child: const Icon(Icons.call_end,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoViews() {
    if (_engine == null) return const SizedBox();
    return Stack(
      children: [
        Center(
          child: AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine!,
              canvas: VideoCanvas(uid: _remoteUid),
              connection:
                  RtcConnection(channelId: widget.chatId),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          width: 120,
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: Colors.blueGrey,
            backgroundImage:
                widget.callerPhotoUrl.isNotEmpty
                    ? NetworkImage(widget.callerPhotoUrl)
                    : null,
            child: widget.callerPhotoUrl.isEmpty
                ? const Icon(Icons.person,
                    size: 65, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            widget.callerDisplayName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _formatDuration(_callDurationInSeconds),
            style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
