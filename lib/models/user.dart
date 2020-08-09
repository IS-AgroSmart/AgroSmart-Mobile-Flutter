import 'dart:convert';

class User {

  final int pk;
  final String username, name, email, type,organization;
  final bool isStaff;

  User(
      {this.pk,
      this.username,
      this.name,
      this.email,
      this.isStaff,
      this.type,
      this.organization
      });

  factory User.fromMap(Map<String, dynamic> json) {
    if (!json.containsKey("username")) throw ArgumentError("username");
    if (!json.containsKey("email")) throw ArgumentError("email");
    if (!json.containsKey("first_name")) throw ArgumentError("first_name");
    if (!json.containsKey("organization")) throw ArgumentError("organization");
    if (!json.containsKey("is_staff")) throw ArgumentError("is_staff");
    if (!json.containsKey("type")) throw ArgumentError("type");
    if (!json.containsKey("pk")) throw ArgumentError("pk");

    return User(
      username: json["username"],
      email: json["email"],
      isStaff: json['is_staff'],
      type: json['type'],
      pk: json['pk'],
      name: json["first_name"],
      organization: json['organization'],
    );
  }

  static List<User> parse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<User>((json) => User.fromMap(json)).toList();
  }
}
