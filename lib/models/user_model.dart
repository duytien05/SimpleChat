class User {
  String name;
  String phone;
  String email;
  String password;

  User({
    required this.name,
    required this.phone,
    this.email = "",
    this.password = "",
  });
}
