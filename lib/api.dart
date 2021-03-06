import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_app/helpers.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'models/flight.dart';
import 'models/user.dart';
import 'models/block.dart';
import 'orthomosaic_preview.dart';

class Api {
  static const ENTRYPOINTG = 'http://droneapp.ngrok.io/';
  static const ENTRYPOINT = ENTRYPOINTG + "api";
  static const ENTRYPOINTNODE = ENTRYPOINTG + "nodeodm/";

  // ignore: cancel_subscriptions
  static StreamSubscription connectivitySubscription;
  static var client = http.Client();

  static const platform =
      const MethodChannel('com.droneapp.flutter_app/downloads');

  static Future<String> _getDownloadsFolder() async {
    try {
      return await platform.invokeMethod('getDownloadsFolder');
    } on PlatformException {
      return "";
    }
  }

  static Future<bool> tryLogin(String username, String pass) async {
    var response = await client.post(ENTRYPOINT + "/api-auth",
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

  static void iOSPermission(FirebaseMessaging _firebaseMessaging) {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

  static Future<bool> saveUIDevice() async {
    final prefs = await SharedPreferences.getInstance();
    String username = prefs.getString("username");
    String os = Platform.isIOS ? "ios" : "android";

    FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
    if (Platform.isIOS) iOSPermission(_firebaseMessaging);

    String tokenDevice = await _firebaseMessaging.getToken();
    print(tokenDevice);

    var response = await client.post(ENTRYPOINT + "/register-push/" + os,
        body: {"username": username, "token": tokenDevice});

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  static Future<List<String>> tryCreateAccount(String username, String pass,
      String email, String name, String organization) async {
    var response = await client.post(ENTRYPOINT + "/users/", body: {
      "username": username,
      "password": pass,
      "email": email,
      "organization": organization,
      "first_name": name
    });
    if (response.statusCode == 201) {
      tryLogin(username, pass);
      return [];
    }
    return _parseErrorDict(utf8.decode(response.bodyBytes));
  }

  static Future<bool> tryResetPassword(String email) async {
    var response = await client
        .post(ENTRYPOINT + "/password_reset/", body: {"email": email});
    return response.statusCode == 200;
  }

  static List<String> _parseErrorDict(String errorJson) {
    return json
        .decode(errorJson)
        .entries
        .map((e) => e.value.map((msg) => e.key + ": " + msg).join("\n"))
        .toList()
        .cast<String>();
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

    final response = await client.get(ENTRYPOINT + '/users',
        headers: {"Authorization": "Token " + (await getToken())});
    if (response.statusCode == 200) {
      var users = User.parse(response.body)
          .where((u) => u.username == username)
          .toList();
      assert(users.length == 1);
      Helpers.loggedInUser = users.first;
      return users.first;
    } else {
      throw Exception(response.body);
    }
  }

  static Future<List<User>> fetchUsersRequest() async {
    final response = await client.get(ENTRYPOINT + '/users',
        headers: {"Authorization": "Token " + (await getToken())});
    var users;
    if (response.statusCode == 200) {
      users = User.parse(response.body)
          .where((u) => u.type == "DEMO_USER")
          .toList();
      return users;
    } else {
      throw Exception(response.body);
    }
  }

  static Future<List<User>> fetchUsersActive() async {
    final response = await client.get(ENTRYPOINT + '/users',
        headers: {"Authorization": "Token " + (await getToken())});
    var users;
    if (response.statusCode == 200) {
      users = User.parse(response.body)
          .where((u) =>
              u.type == "ACTIVE" ||
              u.type == "ADMIN" && Helpers.loggedInUser.pk != u.pk)
          .toList();
      return users;
    } else {
      throw Exception(response.body);
    }
  }

  static Future<List<User>> fetchUsersRequestDeleted() async {
    final response = await client.get(ENTRYPOINT + '/users',
        headers: {"Authorization": "Token " + (await getToken())});
    var users;
    if (response.statusCode == 200) {
      users =
          User.parse(response.body).where((u) => u.type == "DELETED").toList();
      return users;
    } else {
      throw Exception(response.body);
    }
  }

  static Future<String> deletedUser(String idUser) async {
    final response = await client.delete(ENTRYPOINT + '/users/' + idUser + '/',
        headers: {"Authorization": "Token " + (await getToken())});
    if (response.statusCode != 204) {
      return "La solicitud ha fallado, por favor intente mas tarde";
    }
    return "La solicitud se ha completado con exito\n si los cambios no se muestran por favor recarge la pagina..";
  }

  static Future<String> updateTypeUser(id, newType) async {
    var response = await client.patch(ENTRYPOINT + '/users/' + id + '/',
        headers: {
          "Authorization": "Token " + (await getToken()),
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'type': newType,
        }));
    if (response.statusCode != 200) {
      return "La solicitud ha fallado, por favor intente mas tarde";
    }
    return "La solicitud se ha completado con exito\n si los cambios no se muestran por favor recarge la pagina..";
  }

  static Future<List<Flight>> fetchCompleteOrErroredFlights() async {
    return _fetchConditionFlights((flight) =>
        flight.state == FlightState.COMPLETE ||
        flight.state == FlightState.ERROR ||
        flight.state == FlightState.CANCELED);
  }

  static Future<List<Flight>> fetchProcessingFlights() async {
    return _fetchConditionFlights(
        (flight) => flight.state == FlightState.PROCESSING);
  }

  static Future<int> cancelProcessingFlight(Flight flight) async {
    var details = await client
        .post(ENTRYPOINTNODE + "/task/cancel", body: {"uuid": flight.uuid});
    return details.statusCode;
  }

  static Future<List<Flight>> fetchWaitingFlights() async {
    return _fetchConditionFlights(
        (flight) => flight.state == FlightState.WAITING);
  }

  static Future<List<Flight>> fetchDeletedFlights() async {
    final response = await client.get(ENTRYPOINT + '/flights/deleted',
        headers: {"Authorization": "Token " + (await getToken())});
    if (response.statusCode == 200) {
      return Flight.parseList(response.body).toList();
    } else {
      throw Exception(response.body);
    }
  }

  static Future<List<Flight>> _fetchConditionFlights(
      bool Function(Flight) predicate) async {
    final response = await client.get(ENTRYPOINT + '/flights',
        headers: {"Authorization": "Token " + (await getToken())});
    if (response.statusCode == 200) {
      return Flight.parseList(response.body).where(predicate).toList();
    } else {
      throw Exception(response.body);
    }
  }

  static Future<Flight> fetchFlightDetails(Flight f) async {
    final response = await client.get(ENTRYPOINT + '/flights/${f.uuid}',
        headers: {"Authorization": "Token " + (await getToken())});
    if (response.statusCode == 200) {
      return Flight.fromMap(json.decode(response.body).cast<String, dynamic>());
    }
    return null;
  }

  static Future<bool> tryCreateFlight(Flight f) async {
    final response = await client.post(ENTRYPOINT + '/flights/', headers: {
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
    final response = await client.delete(ENTRYPOINT + '/flights/${f.uuid}/',
        headers: {"Authorization": "Token " + (await getToken())});
    return response.statusCode == 201;
  }

  static Future<bool> tryRestoreFlight(Flight f) async {
    final response = await client.patch(ENTRYPOINT + '/flights/${f.uuid}/',
        headers: {"Authorization": "Token " + (await getToken())},
        body: {"deleted": false.toString()});
    return response.statusCode == 200;
  }

  static Future<List<FlightResult>> getAvailableResults(Flight f) async {
    return [FlightResult.MODEL3D, FlightResult.ORTHOMOSAIC];
  }

  static Future<void> downloadList(
      Flight f, Map<String, bool> listDownloads) async {
    Map<String, FlightResult> values = {
      '3d': FlightResult.MODEL3D,
      'cloud': FlightResult.CLOUD,
      'mosaico': FlightResult.ORTHOMOSAIC
    };
    listDownloads.forEach((k, v) => v ? download(f, values[k]) : null);
  }

  static Future<void> download(Flight f, FlightResult result) async {
    const urls = {
      FlightResult.ORTHOMOSAIC: "orthomosaic.png",
      FlightResult.MODEL3D: "3dmodel",
      FlightResult.CLOUD: "foo"
    };

    if (!(await _askPermission())) return;
    Directory downloadDir =
        Directory((await _getDownloadsFolder()) + "/DroneApp/${f.name}");
    if (!downloadDir.existsSync()) await downloadDir.create(recursive: true);
    String saveDir = downloadDir.path;
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

  static Future<void> downloadReport(
      Flight f, Map<String, bool> listReports) async {
    Map<String, String> values = {
      '3d': '3',
      'cloud': 'c',
      'mosaico': 'm',
      'generales': 'g',
      'ndvi': 'n',
    };

    String details = '';
    listReports.forEach((k, v) => details += v ? values[k] : "");
    details += details.length > 0 ? "/" : "";
    if (!(await _askPermission())) return;

    Directory downloadDir =
        Directory((await _getDownloadsFolder()) + "/DroneApp/${f.name}");
    if (!downloadDir.existsSync()) await downloadDir.create(recursive: true);
    String saveDir = downloadDir.path;

    print(saveDir);
    final url = "$ENTRYPOINT/downloads/${f.uuid}/${details}report.pdf";

    FlutterDownloader.enqueue(
      url: url,
      savedDir: saveDir,
      showNotification: true,
      // show download progress in status bar (for Android)
      openFileFromNotification:
          true, // click on notification to open downloaded file (for Android)
    );
  }

  static Future<bool> _askPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      return (await Permission.storage.request()).isGranted;
    }
    return true;
  }

  static checkConection() async {
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult connectivityResult) {
      return connectivityResult == ConnectivityResult.none;
    });
  }

  static Future<List<String>> tryChangePassword(String newPassword) async {
    var response = await client.post(
        ENTRYPOINT +
            "/users/" +
            Helpers.loggedInUser.pk.toString() +
            "/set_password/",
        headers: {"Authorization": "Token " + (await getToken())},
        body: {"password": newPassword});
    if (response.statusCode == 200) {
      return [];
    }
    return _parseErrorDict(utf8.decode(response.bodyBytes));
  }

  static Future<List<Block>> fetchBlockRequest() async {
    final response = await client.get(ENTRYPOINT + '/block_criteria',
        headers: {"Authorization": "Token " + (await getToken())});
    var blocks;
    if (response.statusCode == 200) {
      blocks = Block.parse(response.body)
          .toList();
      return blocks;
    } else {
      throw Exception(response.body);
    }
  }


  static Future<bool> tryDeleteBlock(Block b) async {
    final response = await client.delete(ENTRYPOINT + '/block_criteria/${b.pk}/',
        headers: {"Authorization": "Token " + (await getToken())});
    return response.statusCode == 201;
  }


  static Future<bool> tryCreateBlock(Block b) async {
    final response = await client.post(ENTRYPOINT + '/block_criteria/', headers: {
      "Authorization": "Token " + (await getToken())
    }, body: {
      "value": b.value,
      "type": b.type,
      "ip": b.ip,
    });
    return response.statusCode == 201;
  }

}
