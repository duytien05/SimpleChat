import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import 'chat_list_screen.dart';
import '../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController txtName = TextEditingController();
  final TextEditingController txtMobile = TextEditingController();
  final TextEditingController txtBirthday = TextEditingController();
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  final TextEditingController txtConfirmPassword = TextEditingController();

  @override
  void dispose() {
    txtName.dispose();
    txtMobile.dispose();
    txtBirthday.dispose();
    txtEmail.dispose();
    txtPassword.dispose();
    txtConfirmPassword.dispose();
    super.dispose();
  }

  Widget buildInput(
    String hint,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType? type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }

  Future<void> selectBirthday() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        txtBirthday.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Widget buildBirthdayInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: txtBirthday,
        readOnly: true,
        onTap: selectBirthday,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.birthday,
          border: InputBorder.none,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 120),

              Text(
                AppLocalizations.of(context)!.signup,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                AppLocalizations.of(context)!.addDetailsSignup,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              buildInput(AppLocalizations.of(context)!.name, txtName),

              buildInput(
                AppLocalizations.of(context)!.email,
                txtEmail,
                type: TextInputType.emailAddress,
              ),

              buildInput(
                AppLocalizations.of(context)!.mobile,
                txtMobile,
                type: TextInputType.phone,
              ),

              buildBirthdayInput(),

              buildInput(
                AppLocalizations.of(context)!.password,
                txtPassword,
                obscure: true,
              ),

              buildInput(
                AppLocalizations.of(context)!.confirmPassword,
                txtConfirmPassword,
                obscure: true,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: btnSignUp,
                  child: Text(
                    AppLocalizations.of(context)!.signup,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.alreadyHaveAccount,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.login),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void btnSignUp() async {
    if (txtPassword.text.trim() != txtConfirmPassword.text.trim()) {
      showMsg(AppLocalizations.of(context)!.passwordNotMatch);
      return;
    }

    var response = await AuthService.register({
      "name": txtName.text.trim(),
      "email": txtEmail.text.trim(),
      "mobile": txtMobile.text.trim(),
      "birthday": txtBirthday.text.trim(),
      "password": txtPassword.text.trim(),
    });

    if (response["success"]) {
      AuthService.currentUser = {
        "name": txtName.text.trim(),
        "email": txtEmail.text.trim(),
        "mobile": txtMobile.text.trim(),
        "birthday": txtBirthday.text.trim(),
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );
    } else {
      showMsg(response["message"]);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
