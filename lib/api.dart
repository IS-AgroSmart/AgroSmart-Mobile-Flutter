import 'dart:convert';
import 'dart:io';

import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/flight.dart';
import 'models/user.dart';
import 'orthomosaic_preview.dart';

class Api {
  static const ENTRYPOINT =
//      "https://391b5808-8024-4864-bda1-992db1ce4e6a.mock.pstmn.io";
      "http://10.0.2.2/api";

//      "http://192.168.100.100/api";

  static Future<bool> tryLogin(String username, String pass) async {
    var response = await http.post(ENTRYPOINT + "/api-auth",
        body: {"username": username, "password": pass});

    if (response.statusCode != 200) {
      return false;
    }
    var token = json.decode(response.body)["token"];

    // Save token to global store
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username);
    await prefs.setString("token", token);

    await fetchUserDetails();

    return true;
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("username");
    await prefs.remove("token");
  }

  static Future<User> fetchUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    var username = prefs.getString("username");

    final response = await http.get(ENTRYPOINT + '/users',
        headers: {"Authorization": "Token " + (await getToken())});
    if (response.statusCode == 200) {
      var users = User.parse(response.body)
          .where((u) => u.username == username)
          .toList();
      assert(users.length == 1);
      Helpers.loggedInUser = users[0];
      return users[0];
    } else {
      throw Exception(response.body);
    }
  }

  static Future<List<Flight>> fetchCompleteOrErroredFlights() async {
    return _fetchConditionFlights((flight) =>
        flight.state == FlightState.COMPLETE ||
        flight.state == FlightState.ERROR);
  }

  static Future<List<Flight>> fetchProcessingFlights() async {
    return _fetchConditionFlights(
        (flight) => flight.state == FlightState.PROCESSING);
  }

  static Future<List<Flight>> fetchWaitingFlights() async {
    return _fetchConditionFlights(
        (flight) => flight.state == FlightState.WAITING);
  }

  static Future<List<Flight>> _fetchConditionFlights(
      bool Function(Flight) predicate) async {
    final response = await http.get(ENTRYPOINT + '/flights',
        headers: {"Authorization": "Token " + (await getToken())});
    if (response.statusCode == 200) {
      return Flight.parseList(response.body).where(predicate).toList();
    } else {
      throw Exception(response.body);
    }
  }

  static Future<Flight> fetchFlightDetails(Flight f) async {
    final response = await http.get(ENTRYPOINT + '/flights/${f.uuid}',
        headers: {"Authorization": "Token " + (await getToken())});
    if (response.statusCode == 200) {
      print("Updating");
      return Flight.fromMap(
          json.decode(response.body).cast<String, dynamic>());
    }
    return null;
  }

  static Future<bool> tryCreateFlight(Flight f) async {
    final response = await http.post(ENTRYPOINT + '/flights/', headers: {
      "Authorization": "Token " + (await getToken())
    }, body: {
      "name": f.name,
      "date": Flight.flightInputFormatter.format(f.date),
      "camera": "RGB",
      "multispectral": "false",
      "annotations": f.description,
    });
    return response.statusCode == 201;
  }

  static Future<bool> tryDeleteFlight(Flight f) async {
    final response = await http.delete(ENTRYPOINT + '/flights/${f.uuid}/',
        headers: {"Authorization": "Token " + (await getToken())});
    return response.statusCode == 201;
  }

  static Future<List<FlightResult>> getAvailableResults(Flight f) async {
    return [FlightResult.MODEL3D, FlightResult.ORTHOMOSAIC];
  }

  static Future<void> download(Flight f, FlightResult result) async {
    const urls = {
      FlightResult.ORTHOMOSAIC: "orthomosaic.png",
      FlightResult.MODEL3D: "3dmodel"
    };

    Directory downloadDir = Directory(
        (await DownloadsPathProvider.downloadsDirectory).path +
            "/DroneApp/${f.name}");
    if (!downloadDir.existsSync()) await downloadDir.create(recursive: true);
    String saveDir = downloadDir.path;
//    String saveDir = "$appDataDir/${f.uuid}/${result.toString()}";
    print(saveDir);
    final url = "$ENTRYPOINT/downloads/${f.uuid}/${urls[result]}";

    FlutterDownloader.enqueue(
      url: url,
      savedDir: saveDir,
      showNotification: true,
      // show download progress in status bar (for Android)
      openFileFromNotification:
          true, // click on notification to open downloaded file (for Android)
    );
  }
}
