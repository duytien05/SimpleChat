import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controller cho chỉnh sửa thông tin cá nhân
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Controller cho đổi mật khẩu
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Hàm chọn ảnh từ máy tính/thiết bị cá nhân (Tối ưu cho Flutter Web)
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null &&
          result.files.first.bytes != null) {
        final bytes = result.files.first.bytes!;

        // Chuyển đổi sang định dạng dữ liệu chuỗi Base64 hợp lệ để lưu trữ trực tiếp lên Firestore
        String base64Str = base64Encode(bytes);
        String fullImageUrl =
            'data:image/png;base64,$base64Str';

        final uid = FirebaseAuth.instance.currentUser!.uid;

        // Cập nhật đường dẫn ảnh mới lên Firestore database
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'photoUrl': fullImageUrl,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                  'Cập nhật ảnh đại diện thành công!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text('Lỗi tải ảnh: $e')),
      );
    }
  }

  // Dialog Chỉnh sửa thông tin cá nhân
  void _showEditProfileDialog(
      String currentName, String currentPhone) {
    _nameController.text = currentName;
    _phoneController.text = currentPhone;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Họ và tên')),
            TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Số điện thoại')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final uid =
                  FirebaseAuth.instance.currentUser!.uid;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({
                'displayName': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
              });
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text(
                        'Cập nhật thông tin thành công!')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // Dialog Đổi mật khẩu
  void _showChangePasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Mật khẩu cũ'),
                validator: (v) => v!.isEmpty
                    ? 'Vui lòng nhập mật khẩu cũ'
                    : null,
              ),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới'),
                validator: (v) => v!.length < 6
                    ? 'Mật khẩu mới phải từ 6 ký tự trở lên'
                    : null,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới'),
                validator: (v) => v !=
                        _newPasswordController.text
                    ? 'Mật khẩu xác nhận không trùng khớp'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await _authService.changePassword(
                    oldPassword:
                        _oldPasswordController.text,
                    newPassword:
                        _newPasswordController.text,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                            'Đổi mật khẩu thành công!')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                        backgroundColor: Colors.red,
                        content: Text(e
                            .toString()
                            .replaceAll(
                                'Exception: ', ''))),
                  );
                }
              }
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
          body: Center(
              child: Text('Người dùng chưa đăng nhập.')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Trang cá nhân SimpleChat',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0068FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.password,
                color: Colors.white),
            tooltip: 'Đổi mật khẩu',
            onPressed: _showChangePasswordDialog,
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(
                    'Đã xảy ra lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: CircularProgressIndicator());
          }

          var data =
              snapshot.data!.data() as Map<String, dynamic>;

          String name =
              data['displayName'] ?? 'Chưa cập nhật';
          String phone = data['phone'] ?? 'Chưa cập nhật';
          String email = data['email'] ?? '';
          String birthDate =
              data['birthDate'] ?? 'Chưa cập nhật';
          String photoUrl = data['photoUrl'] ?? '';

          ImageProvider? getAvatarImage() {
            if (photoUrl.isEmpty) return null;
            if (photoUrl.startsWith('data:image')) {
              try {
                final base64String = photoUrl.split(',')[1];
                return MemoryImage(
                    base64Decode(base64String));
              } catch (_) {
                return null;
              }
            }
            return NetworkImage(photoUrl);
          }

          final avatarImage = getAvatarImage();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor:
                            const Color(0xFF0068FF),
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          borderRadius:
                              BorderRadius.circular(20),
                          child: const CircleAvatar(
                            backgroundColor:
                                Color(0xFF0068FF),
                            radius: 20,
                            child: Icon(Icons.camera_alt,
                                size: 18,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(name,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email,
                              color: Color(0xFF0068FF)),
                          title: const Text('Email'),
                          subtitle: Text(email),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.phone,
                              color: Color(0xFF0068FF)),
                          title:
                              const Text('Số điện thoại'),
                          subtitle: Text(phone),
                          trailing: const Icon(Icons.edit,
                              size: 20, color: Colors.grey),
                          onTap: () =>
                              _showEditProfileDialog(
                                  name, phone),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.cake,
                              color: Color(0xFF0068FF)),
                          title: const Text('Ngày sinh'),
                          subtitle: Text(birthDate),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize:
                        const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AuthScreen()));
                  },
                  child: const Text('ĐĂNG XUẤT',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
