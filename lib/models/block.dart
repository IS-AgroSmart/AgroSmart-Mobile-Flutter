import 'dart:convert';

class Block {

  final int pk;
  final String value, ip, type;

  Block(
      {this.pk,
        this.value,
        this.ip,
        this.type,
      });

  factory Block.fromMap(Map<String, dynamic> json) {
    if (!json.containsKey("value") && !json.containsKey("ip")) throw ArgumentError("data not provided");
    if (!json.containsKey("type")) throw ArgumentError("type not provided");
    //if (!json.containsKey("pk")) throw ArgumentError("pk not provided");

    return Block(
      ip: json["ip"],
      value: json["value"],
      type: json['type'],
      pk: json['pk'],
    );
  }

  static List<Block> parse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Block>((json) => Block.fromMap(json)).toList();
  }
}


enum Option { EMAIL, USER_NAME, IP, DOMAIN }

class OptionHelper {
  static String description(Option o) =>
      {Option.EMAIL: "EMAIL", Option.USER_NAME: "USER_NAME", Option.DOMAIN: "DOMAIN", Option.IP: "IP"}[o];

  static String toJson(Option o) =>
      {Option.EMAIL: "EMAIL", Option.USER_NAME: "USER_NAME", Option.DOMAIN: "DOMAIN", Option.IP: "IP"}[o];
}