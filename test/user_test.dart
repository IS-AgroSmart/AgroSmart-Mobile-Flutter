import 'dart:convert';

import 'package:flutter_app/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/user.dart';

import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(
      {"token": "faketoken", "username": "foo"});

  var client;

  setUp(() {
    client = MockClient();
    Api.client = client;

    var response = [
      {
        "id": 1,
        "email": "foo@example.com",
        "first_name": "Me",
        "username": "foo",
        "organization": "Acme Corp.",
        "is_staff": false,
        "pk": 1,
        "type": "ADMIN"
      }
    ];
    when(client.get("http://droneapp.ngrok.io/api/users",
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode(response), 200));
  });

  test("User should be created from map", () {
    User u = User.fromMap({
      "username": "foo",
      "email": "bar",
      "is_staff": false,
      "type": "ADMIN",
      "pk": 1,
      "first_name": "My Name",
      "organization": "Acme Corp.",
    });
    expect(u.username, "foo");
    expect(u.email, "bar");
  });

  test("User should have email", () {
    expect(() => User.fromMap({"username": "foo"}), throwsArgumentError);
  });

  test("Should parse single user", () {
    expect(
        User.parse(
                '[{"username": "foo", "email": "bar", "is_staff": false, "pk": 1, "type": "ADMIN", "first_name": "My Name", "organization": "Acme Corp."}]')
            .length,
        1);
  });

  test("Should parse multiple users", () {
    expect(
        User.parse(
                '[{"username":"a","email":"a", "is_staff": false, "pk": 1, "type": "ADMIN", "first_name": "My Name", "organization": "Acme Corp."}, {"username":"b","email":"b", "is_staff": false, "pk": 2, "type": "ADMIN", "first_name": "My Other Name", "organization": "Acme Corp."}]')
            .length,
        2);
  });

  test("Should fetch & parse user", () async {
    var user = await Api.fetchUserDetails();
    expect(user, isA<User>());
    expect(user.email, "foo@example.com");

//    verify(client.get(any, headers: anyNamed("headers"))).called(1); // Can't call multiple verify() on same test!
    expect(
        verify(client.get(any, headers: captureAnyNamed("headers")))
            .captured
            .single,
        containsValue("Token faketoken"));
  });
}
