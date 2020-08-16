import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/flight_detail_widget.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/new_flight.dart';
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
        "processing_time": 63 * 60 * 1000,
        "state": "PROCESSING",
        "nodeodm_info": {
          "progress": 50,
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

  testWidgets('CompletedFlightsWidget has a title and floating button',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());
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
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

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
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  /*testWidgets('CompletedFlightsWidget has a spinning progress indicator',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });*/

  test("CompletedFlightsWidget has the correct route name", () {
    expect(CompletedFlightsWidget.routeName, "/flights/complete");
  });

  testWidgets("CompletedFlightsWidget calls the API and passes token",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    var verifier =
        verify(client.get(captureAny, headers: captureAnyNamed("headers")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/flights");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("CompletedFlightsWidget shows only completed flights",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    expect(find.text("flightname"), findsOneWidget);
    expect(find.text("yetanotherflight"), findsNothing);
    expect(find.text("anotherflight"), findsNothing);
  });

  testWidgets("CompletedFlightsWidget shows status icons",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    var ws = tester.allWidgets;
    var findIcon = (IconData i) =>
        ws.where((w) => w is Icon).where((w) => (w as Icon).icon == i);
    expect(findIcon(Icons.check), hasLength(1));
    expect(findIcon(Icons.error), hasLength(1));
    expect(findIcon(Icons.cancel), hasLength(1));
  });

  testWidgets("CompletedFlightsWidget shows trash icon",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo"));
    expect(deleteButton, findsOneWidget);
  });

  testWidgets("CompletedFlightsWidget shows alert when deleting",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo"));
    expect(find.text("Confirmar eliminación"), findsNothing);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text("Confirmar eliminación"), findsOneWidget);

    await tester.tap(find.text("Cancelar"));
    await tester.pumpAndSettle();
    expect(find.text("Confirmar eliminación"), findsNothing);
  });

  testWidgets("CompletedFlightsWidget deletes flight",
      (WidgetTester tester) async {
    when(client.delete(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("", 204));
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo"));
    expect(find.text("Confirmar eliminación"), findsNothing);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text("Confirmar eliminación"), findsOneWidget);

    await tester.tap(find.text("Eliminar"));
    await tester.pumpAndSettle();
    var verifier =
        verify(client.delete(captureAny, headers: captureAnyNamed("headers")));
    expect(
        verifier.captured[0], "http://droneapp.ngrok.io/api/flights/uuidfoo/");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("CompletedFlightsWidget shows snackbar if delete fails",
      (WidgetTester tester) async {
    when(client.delete(any, headers: anyNamed("headers")))
        .thenThrow(SocketException("dummy"));
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo"));
    expect(find.text("Confirmar eliminación"), findsNothing);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text("Confirmar eliminación"), findsOneWidget);

    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.text("Eliminar"));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text("Error al eliminar el vuelo"), findsOneWidget);
  });

  testWidgets("CompletedFlightsWidget pops modal if canceled",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo"));
    expect(find.text("Confirmar eliminación"), findsNothing);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text("Confirmar eliminación"), findsOneWidget);
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
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    verify(mockObserver.didPush(any, any));
    expect(find.byType(NewFlightWidget), findsOneWidget);
  });

  testWidgets("Clicking on flight navigates to FlightDetail",
      (WidgetTester tester) async {
    when(client.get("http://droneapp.ngrok.io/api/flights/uuidfoo",
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(
            jsonEncode({
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
            }),
            200));
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(ListTile),
        findsNWidgets(3)); // One complete, one failed, one canceled

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    verify(mockObserver.didPush(any, any));
    expect(find.byType(FlightDetailWidget), findsOneWidget);
  });

  testWidgets("routeNameFunc() return correct route",
      (WidgetTester tester) async {
    expect(CompletedFlightsWidget().routeNameFunc(), "/flights/complete");
  });
}
