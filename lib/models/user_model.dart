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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      password: json['password'],
    );
  }
}
