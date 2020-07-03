import 'dart:convert';

class User {
  final String username, name, email;

  User({this.username, this.name, this.email});

  factory User.fromMap(Map<String, dynamic> json) {
    if (!json.containsKey("username")) throw ArgumentError("username");
    if (!json.containsKey("email")) throw ArgumentError("email");
    return User(
      username: json["username"],
      email: json["email"],
    );
  }

  static List<User> parse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<User>((json) => User.fromMap(json)).toList();
  }
}
