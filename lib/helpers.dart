import 'package:shared_preferences/shared_preferences.dart';

import 'models/user.dart';

class Helpers {
  static User loggedInUser;

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("token") != null;
  }
}
