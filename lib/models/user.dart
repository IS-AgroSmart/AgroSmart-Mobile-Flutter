import 'dart:convert';

class User {
  final String username, name, email, organization, pk;

  User({this.username, this.name, this.email,this.organization,this.pk});

  factory User.fromMap(Map<String, dynamic> json) {
    if (!json.containsKey("username")) throw ArgumentError("username");
    if (!json.containsKey("email")) throw ArgumentError("email");
    if (!json.containsKey("first_name")) throw ArgumentError("first_name");
    if (!json.containsKey("organization")) throw ArgumentError("organization");
    return User(
      username: json["username"],
      email: json["email"],
      name: json["first_name"],
      organization: json['organization'],
      pk: json["pk"].toString(),
    );
  }

  static List<User> parse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<User>((json) => User.fromMap(json)).toList();
  }
}
