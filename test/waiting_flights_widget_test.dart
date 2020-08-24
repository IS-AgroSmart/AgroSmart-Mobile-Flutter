import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/flight_detail_widget.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/new_flight.dart';
import 'package:flutter_app/waiting_flights_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();
  SharedPreferences.setMockInitialValues(
      {"token": "faketoken", "username": "foo"});

  Helpers.loggedInUser = User(
      pk: 1,
      username: "myusername",
      name: "myname",
      email: "email@example.com",
      isStaff: false,
      type: "ADMIN");
  var client, mockObserver;

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
        "name": "failedflight",
        "annotations": "some notes",
        "date": "2020-01-01",
        "processing_time": 6000,
        "state": "ERROR",
        "nodeodm_info": {
          "progress": 100,
        },
        "camera": "RGB",
        "deleted": false
      },
      {
        "uuid": "uuidfoo3",
        "name": "canceledflight",
        "annotations": "some notes",
        "date": "2020-01-01",
        "processing_time": 6000,
        "state": "CANCELED",
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
        "processing_time": 0,
        "state": "WAITING",
        "nodeodm_info": {
          "progress": 0,
        },
        "camera": "RGB",
        "deleted": false
      }
    ];

    mockObserver = MockNavigatorObserver();
    client = MockClient();
    Api.client = client;
    when(client.get("http://droneapp.ngrok.io/api/flights",
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode(response), 200));
  });

  Future<void> pumpArgumentWidget(
    WidgetTester tester, {
    @required Object args,
    @required Widget child,
  }) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [mockObserver],
        routes: {
          NewFlightWidget.routeName: (context) => NewFlightWidget(),
        },
        home: FlatButton(
          onPressed: () => key.currentState.push(
            MaterialPageRoute<void>(
              settings: RouteSettings(arguments: args),
              builder: (_) => child,
            ),
          ),
          child: const SizedBox(),
        ),
      ),
    );
    await tester.tap(find.byType(FlatButton));
    await tester.pumpAndSettle();
  }

  testWidgets('WaitingFlightsWidget has a title and floating button',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: WaitingFlightsWidget());
    expect(find.text("Vuelos pendientes"), findsOneWidget);
  });

  testWidgets("WaitingFlightsWidget shows New Flight if user is not demo",
      (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "demo",
        name: "Demo User",
        email: "notdemo@example.com",
        isStaff: false,
        type: "ACTIVE");
    await pumpArgumentWidget(tester, args: null, child: WaitingFlightsWidget());

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets("WaitingFlightsWidget doesn't show FAB if user is demo",
      (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "demo",
        name: "Demo User",
        email: "demo@example.com",
        isStaff: false,
        type: "DEMO_USER");
    await pumpArgumentWidget(tester, args: null, child: WaitingFlightsWidget());

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  test("WaitingFlightsWidget has the correct route name", () {
    expect(WaitingFlightsWidget().routeNameFunc(), "/flights/waiting");
  });

  testWidgets("WaitingFlightsWidget calls the API and passes token",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: WaitingFlightsWidget());

    var verifier =
        verify(client.get(captureAny, headers: captureAnyNamed("headers")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/flights");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("WaitingFlightsWidget shows only waiting flights",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: WaitingFlightsWidget());

    expect(find.text("flightname"), findsNothing);
    expect(find.text("yetanotherflight"), findsOneWidget);
    expect(find.text("anotherflight"), findsNothing);
  });

  testWidgets("WaitingFlightsWidget shows status icons",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: WaitingFlightsWidget());

    var ws = tester.allWidgets;
    var findIcon = (IconData i) =>
        ws.where((w) => w is Icon).where((w) => (w as Icon).icon == i);
    expect(findIcon(Icons.map), hasLength(1));
    expect(findIcon(Icons.error), hasLength(0));
    expect(findIcon(Icons.cancel), hasLength(0));
  });

  testWidgets("WaitingFlightsWidget doesn't show trash icon",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: WaitingFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo3"));
    expect(deleteButton, findsNothing);
  });

  testWidgets("Clicking on FAB navigates to New Flight",
      (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "demo",
        name: "Demo User",
        email: "notdemo@example.com",
        isStaff: false,
        type: "ACTIVE");
    await pumpArgumentWidget(tester, args: null, child: WaitingFlightsWidget());
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    verify(mockObserver.didPush(any, any));
    expect(find.byType(NewFlightWidget), findsOneWidget);
  });

  testWidgets("Clicking on flight navigates to FlightDetail",
      (WidgetTester tester) async {
    when(client.get("http://droneapp.ngrok.io/api/flights/uuidfoo3",
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(
            jsonEncode({
              "uuid": "uuidfoo3",
              "name": "yetanotherflight",
              "annotations": "some other notes",
              "date": "2018-03-03",
              "processing_time": 0,
              "state": "WAITING",
              "nodeodm_info": {
                "progress": 0,
              },
              "camera": "RGB",
              "deleted": false
            }),
            200));
    await pumpArgumentWidget(tester, args: null, child: WaitingFlightsWidget());
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(ListTile), findsOneWidget);

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    verify(mockObserver.didPush(any, any));
    expect(find.byType(FlightDetailWidget), findsOneWidget);
  });
}