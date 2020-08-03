import 'dart:convert';

import 'package:flutter_app/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/flight.dart';

import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(
      {"token": "faketoken", "username": "foo"});

  var client;
  const exampleDict = {
    "uuid": "uuidfoo",
    "name": "flightname",
    "annotations": "some notes",
    "date": "2020-01-01",
    "processing_time": 6000,
    "state": "COMPLETE",
    "nodeodm_info": {
      "progress": 100,
    },
    "camera": "RGB",
    "deleted": false
  };

  setUp(() {
    client = MockClient();
    Api.client = client;

    var response = [
      {
        "uuid": "uuidfoo",
        "name": "flightname",
        "annotations": "some notes",
        "date": "2020-01-01",
        "processing_time": 6000,
        "state": "COMPLETE",
        "nodeodm_info": {
          "progress": 100,
        },
        "camera": "RGB",
        "deleted": false
      },
      {
        "uuid": "uuidfoo2",
        "name": "anotherflight",
        "annotations": "some other notes",
        "date": "2019-02-02",
        "processing_time": 60 * 1000,
        "state": "PROCESSING",
        "nodeodm_info": {
          "progress": 10,
        },
        "camera": "RGB",
        "deleted": false
      },
      {
        "uuid": "uuidfoo3",
        "name": "yetanotherflight",
        "annotations": "some other notes",
        "date": "2018-03-03",
        "processing_time": 63 * 60 * 1000,
        "state": "PROCESSING",
        "nodeodm_info": {
          "progress": 50,
        },
        "camera": "RGB",
        "deleted": false
      }
    ];
    when(client.get("http://droneapp.ngrok.io/api/flights",
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode(response), 200));
  });

  test("Flight should be created from map", () {
    Flight f = Flight.fromMap(exampleDict);
    expect(f.name, "flightname");
    expect(f.camera, "RGB");
  });

  test("Should parse single flight", () {
    expect(
        Flight.parseList('[{"uuid": "uuidfoo", "name": "flightname", '
                '"description": "some notes", "date": "2020-01-01", '
                '"processing_time": 6000, "state": "COMPLETE", '
                '"nodeodm_info": {"progress": 100}, "camera": "RGB", '
                '"deleted": false}]')
            .length,
        1);
  });

  test("Should parse multiple flights", () {
    expect(
        Flight.parseList('[{"uuid": "uuidfoo", "name": "flightname", '
                '"description": "some notes", "date": "2020-01-01", '
                '"processing_time": 6000, "state": "COMPLETE", '
                '"nodeodm_info": {"progress": 100}, "camera": "RGB", '
                '"deleted": false},'
                '{"uuid": "uuidfoo2", "name": "otherflight", '
                '"description": "some new notes", "date": "2019-02-02", '
                '"processing_time": 3000, "state": "PROCESSING", '
                '"nodeodm_info": {"progress": 40}, "camera": "MICASENSE", '
                '"deleted": false}]')
            .length,
        2);
  });

  test("Should fetch & parse flight", () async {
    var flights = await Api.fetchCompleteOrErroredFlights();
    expect(flights, isA<List<Flight>>());
    expect(flights.length, 1);

//    verify(client.get(any, headers: anyNamed("headers"))).called(1); // Can't call multiple verify() on same test!
    expect(
        verify(client.get(any, headers: captureAnyNamed("headers")))
            .captured
            .single,
        containsValue("Token faketoken"));
  });

  test("Should show humanized processing time", () async {
    var flights = await Api.fetchProcessingFlights();
    expect(flights[0].humanizedProcessingTime(), "0 h, 1 min");
    expect(flights[1].humanizedProcessingTime(), "1 h, 3 min");
  });

  test("Should show humanized time left", () async {
    var flights = await Api.fetchProcessingFlights();
    expect(flights[0].humanizeTimeLeft(), "0 h, 9 min");
    expect(flights[1].humanizeTimeLeft(), "1 h, 3 min");
  });

  test(
      "CameraHelper toJson method should return the backend key for the camera",
      () {
    expect(CameraHelper.toJson(Camera.MICASENSE), "MICASENSE");
    expect(CameraHelper.toJson(Camera.RGB), "RGB");
  });
}
