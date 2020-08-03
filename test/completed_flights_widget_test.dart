import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'mocks.dart';

void main() {
  var widget, client;

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
    expect(find.byType(FloatingActionButton), findsOneWidget);
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
