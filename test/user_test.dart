import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/user.dart';

void main() {
  test("User should be created from map", () {
    User u = User.fromMap({"username": "foo", "email": "bar"});
    expect(u.username, "foo");
    expect(u.email, "bar");
  });

  test("User should have email", () {
    expect(() => User.fromMap({"username": "foo"}), throwsArgumentError);
  });

  test("Should parse single user", () {
    expect(User.parse('[{"username": "foo", "email": "bar"}]').length, 1);
  });

  test("Should parse multiple users", () {
    expect(User.parse('[{"username":"a","email":"a"}, {"username":"b","email":"b"}]').length, 2);
  });
}
