import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';

class VoiceMessageBubble extends StatefulWidget {
  final String base64Audio;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.base64Audio,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() =>
      _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState
    extends State<VoiceMessageBubble> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Lắng nghe sự thay đổi trạng thái phát
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Lắng nghe tổng độ dài file ghi âm
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    // Lắng nghe tiến trình đang phát thực tế
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer
        .dispose(); // Giải phóng trình phát khi bong bóng chat bị hủy
    super.dispose();
  }

  // Hàm xử lý Phát / Tạm dừng âm thanh từ chuỗi Base64
  void _playPauseAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        String cleanBase64 = widget.base64Audio;
        // Bóc tách lược bỏ phần Header "data:audio/...;base64," nếu có
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',')[1];
        }

        // Giải mã chuỗi thành Bytes dữ liệu thô
        final bytes = base64Decode(cleanBase64);

        // Phát dữ liệu trực tiếp từ vùng nhớ (Hỗ trợ hoàn hảo cho Web và Mobile)
        await _audioPlayer.play(BytesSource(bytes));
      } catch (e) {
        print("Lỗi khi phát tin nhắn thoại: $e");
      }
    }
  }

  // Định dạng hiển thị thời lượng (Ví dụ: 0:05)
  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString();
    String seconds = (duration.inSeconds % 60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán tiến trình chạy của thanh sóng âm thanh (từ 0.0 đến 1.0)
    double progress = (_duration.inMilliseconds > 0)
        ? (_position.inMilliseconds /
            _duration.inMilliseconds)
        : 0.0;

    Color contentColor = widget.isMe
        ? Colors.white
        : const Color(0xFF0068FF);

    return InkWell(
      onTap:
          _playPauseAudio, // Kích hoạt sự kiện click nghe
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 4.0, horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nút điều khiển Play/Pause linh hoạt thay đổi icon trạng thái
            Icon(
              _isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              color: contentColor,
              size: 32,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh tiến trình chạy nhạc thực tế (thay thế cho thanh line xám tĩnh cũ)
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? Colors.white30
                            : Colors.black12,
                        borderRadius:
                            BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 120 * progress,
                      height: 4,
                      decoration: BoxDecoration(
                        color: contentColor,
                        borderRadius:
                            BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Hiển thị thời lượng chạy thực tế của đoạn ghi âm
                Text(
                  _position.inSeconds > 0
                      ? "${_formatDuration(_position)} / ${_formatDuration(_duration)}"
                      : "Tin nhắn thoại",
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isMe
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
