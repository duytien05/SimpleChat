class AuthService {
  static List<Map<String, dynamic>> users = [];

  static Map<String, dynamic>? currentUser;

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> user,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    for (var u in users) {
      if (u["email"] == user["email"]) {
        return {"success": false, "message": "Email đã tồn tại"};
      }
    }

    users.add(user);
    return {"success": true};
  }

  /// LOGIN
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    for (var u in users) {
      if (u["email"] == email && u["password"] == password) {
        currentUser = u;
        return {"success": true};
      }
    }

    return {"success": false, "message": "Sai email hoặc mật khẩu"};
  }
}
