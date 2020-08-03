import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/flight_detail_widget.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'mock_client.dart';

void main() {
  var widget, client;

  setUp(() {
    var response = {
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

    client = MockClient();
    Api.client = client;
    when(client.get(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    widget =
        MaterialApp(home: FlightDetailWidget(flight: Flight.fromMap(response)));
  });

  testWidgets('FlightDetailWidget has a title', (WidgetTester tester) async {
//    await tester.pumpWidget(widget);
//    await tester.pump(Duration.zero);
//    await tester.pumpWidget(widget);
//    await tester.pump(Duration.zero);
//    expect(find.byType(CircularProgressIndicator), findsNothing);
//    expect(find.text("flightname"), findsOneWidget);
//    expect(find.byType(RaisedButton), findsNWidgets(2));
  });
}