import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_navigation.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // Hàm hiển thị hộp thoại chọn Ngày sinh dạng Lịch trực quan
  Future<void> _selectBirthDate(
      BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0068FF),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        // Định dạng ngày hiển thị dd/mm/yyyy
        _birthDateController.text =
            "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      });
    }
  }

  void submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword =
        _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final birthDate = _birthDateController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Vui lòng điền đầy đủ Email và Mật khẩu')),
      );
      return;
    }

    if (!isLogin) {
      if (name.isEmpty ||
          phone.isEmpty ||
          birthDate.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Vui lòng điền đầy đủ các thông tin cá nhân (bao gồm Ngày sinh)')),
        );
        return;
      }
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Mật khẩu nhập lại không trùng khớp!')),
        );
        return;
      }
    }

    try {
      if (isLogin) {
        // Thực hiện Đăng nhập
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const MainNavigation()),
        );
      } else {
        // Thực hiện Đăng ký tài khoản mới
        UserCredential userCredential = await FirebaseAuth
            .instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // ĐỒNG BỘ: Cập nhật thông tin thực tế vào Firestore, bao gồm Ngày sinh đã chọn
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'displayName': name,
          'email': email,
          'phone': phone,
          'birthDate':
              birthDate, // 👈 Đã truyền chính xác biến dữ liệu ngày sinh vào Firestore từ khi đăng ký
          'photoUrl':
              'https://ui-avatars.com/api/?name=$name&background=0D8ABC&color=fff',
          'friends': [],
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e
                .toString()
                .replaceAll(RegExp(r'\[.*?\]'), ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
          const BorderSide(color: Colors.grey, width: 1),
    );

    final focusedBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
          color: Color(0xFF0068FF), width: 1.5),
    );

    return Scaffold(
      backgroundColor: Colors.grey[
          200], // Đổi màu nền qua màu xám nhạt đồng bộ theo yêu cầu của bạn
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0068FF),
        elevation: 0,
        title: isLogin
            ? const Text('SimpleChat',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold))
            : const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text('Tạo tài khoản SimpleChat',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  SizedBox(height: 2),
                  Text('Nhập thông tin để đăng ký',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.normal)),
                ],
              ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isLogin) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF0068FF)),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: borderStyle,
                      focusedBorder: focusedBorderStyle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: const Icon(
                          Icons.phone_android,
                          color: Color(0xFF0068FF)),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: borderStyle,
                      focusedBorder: focusedBorderStyle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: () => _selectBirthDate(context),
                    decoration: InputDecoration(
                      labelText: 'Ngày sinh',
                      hintText: 'Chọn ngày sinh của bạn',
                      prefixIcon: const Icon(
                          Icons.cake_outlined,
                          color: Color(0xFF0068FF)),
                      suffixIcon: const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Color(0xFF0068FF)),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: borderStyle,
                      focusedBorder: focusedBorderStyle,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (Tài khoản)',
                    prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF0068FF)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: borderStyle,
                    focusedBorder: focusedBorderStyle,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF0068FF)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: borderStyle,
                    focusedBorder: focusedBorderStyle,
                  ),
                ),
                if (!isLogin) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận lại mật khẩu',
                      prefixIcon: const Icon(
                          Icons.lock_reset_outlined,
                          color: Color(0xFF0068FF),
                          size: 26),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: borderStyle,
                      focusedBorder: focusedBorderStyle,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF0068FF),
                    elevation: 1,
                    minimumSize:
                        const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10)),
                  ),
                  onPressed: submit,
                  child: Text(
                    isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin
                        ? 'Chưa có tài khoản? Đăng ký ngay'
                        : 'Đã có tài khoản? Đăng nhập',
                    style: const TextStyle(
                        color: Color(0xFF0068FF),
                        fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
