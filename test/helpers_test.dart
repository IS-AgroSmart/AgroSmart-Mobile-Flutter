
import 'package:flutter_app/helpers.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:shared_preferences/shared_preferences.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("Should return loggedIn = true if token set", () async {
    SharedPreferences.setMockInitialValues(
        {"token": "faketoken", "username": "foo"});
    expect(await Helpers.isLoggedIn(), true);
  });

  test("Should return loggedIn = false if token not set", () async {
    SharedPreferences.setMockInitialValues({"token": null, "username": "foo"});
    expect(await Helpers.isLoggedIn(), false);
  });
}
