import 'dart:convert';

class Block {

  final int pk;
  final String value, ip, option;

  Block(
      {this.pk,
        this.value,
        this.ip,
        this.option,
      });

  factory Block.fromMap(Map<String, dynamic> json) {
    if (!json.containsKey("value") && !json.containsKey("ip")) throw ArgumentError("data not provided");
    if (!json.containsKey("option")) throw ArgumentError("option not provided");
    if (!json.containsKey("pk")) throw ArgumentError("pk not provided");

    return Block(
      ip: json["ip"],
      value: json["value"],
      option: json['option'],
      pk: json['pk'],
    );
  }

  static List<Block> parse(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Block>((json) => Block.fromMap(json)).toList();
  }
}
