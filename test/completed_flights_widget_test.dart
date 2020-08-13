import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'mocks.dart';

void main() {
  var widget, client;
  Helpers.loggedInUser = User(
      pk: 1,
      username: "myusername",
      name: "myname",
      email: "email@example.com",
      isStaff: false,
      type: "ADMIN");

  setUp(() {
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

    client = MockClient();
    Api.client = client;
    when(client.get("http://droneapp.ngrok.io/api/flights",
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    widget = MaterialApp(home: CompletedFlightsWidget());
  });

  testWidgets('CompletedFlightsWidget has a title and floating button',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    expect(find.text("Vuelos completos"), findsOneWidget);
  });

  testWidgets("CompletedFlightsWidget shows New Flight if user is not demo",
      (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "demo",
        name: "Demo User",
        email: "notdemo@example.com",
        isStaff: false,
        type: "ACTIVE");
    await tester.pumpWidget(widget);

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets("CompletedFlightsWidget doesn't show FAB if user is demo",
      (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "demo",
        name: "Demo User",
        email: "demo@example.com",
        isStaff: false,
        type: "DEMO_USER");
    await tester.pumpWidget(widget);

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('CompletedFlightsWidget has a spinning progress indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test("CompletedFlightsWidget has the correct route name", () {
    expect(CompletedFlightsWidget.routeName, "/flights/complete");
  });
}
