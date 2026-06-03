import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Chức năng đổi mật khẩu kiểm tra mật khẩu cũ
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("Người dùng chưa đăng nhập.");
    }

    // Bước 1: Xác thực lại bằng mật khẩu cũ (Re-authenticate)
    AuthCredential credential =
        EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      // Bước 2: Tiến hành cập nhật mật khẩu mới nếu mật khẩu cũ đúng
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw Exception("Mật khẩu cũ không chính xác.");
      } else {
        throw Exception(
            e.message ?? "Đã xảy ra lỗi hệ thống.");
      }
    }
  }
}
