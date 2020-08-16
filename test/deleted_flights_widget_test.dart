import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/deleted_flights_widget.dart';
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
        "uuid": "uuidfoo2",
        "name": "anotherflight",
        "annotations": "some other notes",
        "date": "2019-02-02",
        "processing_time": 60 * 1000,
        "state": "COMPLETE",
        "nodeodm_info": {
          "progress": 100,
        },
        "camera": "RGB",
        "deleted": true
      },
      {
        "uuid": "uuidfoo3",
        "name": "yetanotherflight",
        "annotations": "some other notes",
        "date": "2018-03-03",
        "processing_time": 6000,
        "state": "COMPLETE",
        "nodeodm_info": {
          "progress": 100,
        },
        "camera": "RGB",
        "deleted": true
      }
    ];

    mockObserver = MockNavigatorObserver();
    client = MockClient();
    Api.client = client;
    when(client.get("http://droneapp.ngrok.io/api/flights/deleted",
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

  testWidgets('DeletedFlightsWidget has a title and floating button',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());
    expect(find.text("Vuelos eliminados"), findsOneWidget);
  });

  testWidgets("DeletedFlightsWidget shows New Flight if user is not demo",
      (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "demo",
        name: "Demo User",
        email: "notdemo@example.com",
        isStaff: false,
        type: "ACTIVE");
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets("DeletedFlightsWidget doesn't show FAB if user is demo",
      (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "demo",
        name: "Demo User",
        email: "demo@example.com",
        isStaff: false,
        type: "DEMO_USER");
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  test("DeletedFlightsWidget has the correct route name", () {
    expect(DeletedFlightsWidget.routeName, "/flights/deleted");
  });

  testWidgets("DeletedFlightsWidget calls the API and passes token",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    var verifier =
        verify(client.get(captureAny, headers: captureAnyNamed("headers")));
    expect(
        verifier.captured[0], "http://droneapp.ngrok.io/api/flights/deleted");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("DeletedFlightsWidget shows trash & restore icons",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo2"));
    expect(deleteButton, findsOneWidget);
    var restoreButton = find.byKey(Key("restore-icon-uuidfoo2"));
    expect(restoreButton, findsOneWidget);
  });

  testWidgets("DeletedFlightsWidget shows alert when deleting",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo2"));
    expect(find.text("Confirmar eliminación"), findsNothing);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text("Confirmar eliminación"), findsOneWidget);
    expect(
        find.text("¿Confirma que desea eliminar el vuelo?"
            "\n Una vez eliminado no podrá recuperarlo."),
        findsOneWidget);

    await tester.tap(find.text("Cancelar"));
    await tester.pumpAndSettle();
    expect(find.text("Confirmar eliminación"), findsNothing);
  });

  testWidgets("DeletedFlightsWidget deletes flight",
      (WidgetTester tester) async {
    when(client.delete(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("", 204));
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo2"));
    expect(find.text("Confirmar eliminación"), findsNothing);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text("Confirmar eliminación"), findsOneWidget);

    await tester.tap(find.text("Eliminar"));
    await tester.pumpAndSettle();
    var verifier =
        verify(client.delete(captureAny, headers: captureAnyNamed("headers")));
    expect(
        verifier.captured[0], "http://droneapp.ngrok.io/api/flights/uuidfoo2/");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("DeletedFlightsWidget shows snackbar if delete fails",
      (WidgetTester tester) async {
    when(client.delete(any, headers: anyNamed("headers")))
        .thenThrow(SocketException("dummy"));
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo2"));
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.text("Eliminar"));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text("Error al eliminar el vuelo"), findsOneWidget);
  });

  testWidgets("DeletedFlightsWidget restores flight",
      (WidgetTester tester) async {
    when(client.patch(any,
            headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response("", 200));
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    var restoreButton = find.byKey(Key("restore-icon-uuidfoo2"));
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();
    var verifier = verify(client.patch(captureAny,
        headers: captureAnyNamed("headers"), body: captureAnyNamed("body")));
    expect(
        verifier.captured[0], "http://droneapp.ngrok.io/api/flights/uuidfoo2/");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
    expect(verifier.captured[2], containsPair("deleted", "false"));
  });

  testWidgets("DeletedFlightsWidget shows snackbar if restore fails",
      (WidgetTester tester) async {
    when(client.patch(any,
            headers: anyNamed("headers"), body: anyNamed("body")))
        .thenThrow(SocketException("dummy"));
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    var restoreButton = find.byKey(Key("restore-icon-uuidfoo2"));
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text("Error al restaurar el vuelo"), findsOneWidget);
  });

  testWidgets("DeletedFlightsWidget pops modal if canceled",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: DeletedFlightsWidget());

    var deleteButton = find.byKey(Key("delete-icon-uuidfoo2"));
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text("Confirmar eliminación"), findsOneWidget);
    await tester.tap(find.text("Eliminar"));
    await tester.pumpAndSettle();
    expect(find.text("Confirmar eliminación"), findsNothing);
  });

  testWidgets("routeNameFunc() return correct route",
      (WidgetTester tester) async {
    expect(DeletedFlightsWidget().routeNameFunc(), "/flights/deleted");
  });
}
