import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/UserRequests.dart';
import 'package:flutter_app/api.dart';
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
      pk: 8,
      username: "admin",
      name: "admin",
      email: "admin@example.com",
      isStaff: false,
      type: "ADMIN");
  var client, mockObserver;
  const response = [
    {
      "pk": 1,
      "username": "anotheradmin",
      "first_name": "admin",
      "organization": "Acme Corp.",
      "email": "anotheradmin@example.com",
      "is_staff": false,
      "type": "DELETED"
    },
    {
      "pk": 2,
      "username": "normal1",
      "first_name": "normal1",
      "organization": "Acme Corp.",
      "email": "normal1@example.com",
      "is_staff": false,
      "type": "DELETED"
    },
    {
      "pk": 3,
      "username": "request1",
      "first_name": "request1",
      "organization": "Acme Corp.",
      "email": "request1@example.com",
      "is_staff": false,
      "type": "DEMO_USER"
    },
    {
      "pk": 4,
      "username": "request2",
      "first_name": "request2",
      "organization": "Acme Corp.",
      "email": "request2@example.com",
      "is_staff": false,
      "type": "DEMO_USER"
    },
    {
      "pk": 8,
      "username": "admin",
      "first_name": "admin",
      "organization": "Acme Corp.",
      "email": "admin@example.com",
      "is_staff": false,
      "type": "ADMIN"
    },
  ];

  setUp(() {
    mockObserver = MockNavigatorObserver();
    client = MockClient();
    Api.client = client;
    when(client.get("http://droneapp.ngrok.io/api/users",
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

  testWidgets("UserRequestsWidget shows deleted users if Deleted tapped",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());
    reset(client);
    when(client.get("http://droneapp.ngrok.io/api/users",
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode(response), 200));

    await tester.tap(find.text("Eliminados"));
    await tester.pumpAndSettle();

    var verifier =
        verify(client.get(captureAny, headers: captureAnyNamed("headers")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/users");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("UserRequestsWidget filters for deleted users",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());
    await tester.tap(find.text("Eliminados"));
    await tester.pumpAndSettle();

    expect(find.text("normal1"), findsOneWidget);
    expect(find.text("anotheradmin"), findsOneWidget);
    expect(find.text("request1"), findsNothing);
  });

  testWidgets("UserRequestsWidget shows Delete icon",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());
    await tester.tap(find.text("Eliminados"));
    await tester.pumpAndSettle();

    var deleteButton = find.byKey(Key("icon2-user-2"));
    expect(deleteButton, findsOneWidget);
  });

  testWidgets("UserRequestsWidget shows alert when deleting",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());
    await tester.tap(find.text("Eliminados"));
    await tester.pumpAndSettle();

    var rejectButton = find.byKey(Key("icon2-user-2"));
    expect(find.text("¿Realmente quiere Eliminar la solicitud?"), findsNothing);
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();
    expect(
        find.text("¿Realmente quiere Eliminar la solicitud?"), findsOneWidget);

    await tester.tap(find.text("No"));
    await tester.pumpAndSettle();
    expect(find.text("¿Realmente quiere Eliminar la solicitud?"), findsNothing);
  });

  testWidgets("UserRequestsWidget deletes user", (WidgetTester tester) async {
    when(client.delete(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("", 204));
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());
    await tester.tap(find.text("Eliminados"));
    await tester.pumpAndSettle();

    var rejectButton = find.byKey(Key("icon2-user-2"));
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Sí"));
    await tester.pumpAndSettle();

    var verifier =
        verify(client.delete(captureAny, headers: captureAnyNamed("headers")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/users/2/");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("UserRequestsWidget searches for user", (WidgetTester tester) async {
    when(client.delete(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("", 204));
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());
    await tester.tap(find.text("Eliminados"));
    await tester.pumpAndSettle();

    var searchField = find.byType(TextFormField);
    var searchButton = find.descendant(of: searchField, matching: find.byType(IconButton));
    expect(searchButton, findsOneWidget);
    await tester.enterText(searchField, "another");
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    expect(find.text("normal1"), findsNothing);
    expect(find.text("anotheradmin"), findsOneWidget);
  });

  testWidgets("UserRequestsWidget shows message when empty array", (WidgetTester tester) async {
    reset(client);
    when(client.get("http://droneapp.ngrok.io/api/users",
        headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode([]), 200));
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    expect(find.text("No hay solicitudes de usuarios"), findsOneWidget);
  });
}
