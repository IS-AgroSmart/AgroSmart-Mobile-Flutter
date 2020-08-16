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
      pk: 1,
      username: "admin",
      name: "admin",
      email: "admin@example.com",
      isStaff: false,
      type: "ADMIN");
  var client, mockObserver;

  setUp(() {
    var response = [
      {
        "pk": 1,
        "username": "admin",
        "first_name": "admin",
        "organization": "Acme Corp.",
        "email": "admin@example.com",
        "is_staff": false,
        "type": "ADMIN"
      },
      {
        "pk": 2,
        "username": "normal1",
        "first_name": "normal1",
        "organization": "Acme Corp.",
        "email": "normal1@example.com",
        "is_staff": false,
        "type": "ACTIVE"
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
    ];

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

  testWidgets('UserRequestsWidget has a title', (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());
    expect(find.text("Solicitudes de Usuarios"), findsOneWidget);
  });

  test("UserRequestsWidget has the correct route name", () {
    expect(UserRequestsWidget.routeName, "/user/");
  });

  testWidgets("UserRequestsWidget calls the API and passes token",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    var verifier =
        verify(client.get(captureAny, headers: captureAnyNamed("headers")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/users");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("UserRequestsWidget shows only demo users",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    expect(find.text("request1"), findsOneWidget);
    expect(find.text("request2"), findsOneWidget);
    expect(find.text("normal1"), findsNothing);
    expect(find.text("admin"), findsNothing);
  });

  /*testWidgets("UserRequestsWidget shows status icons",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: CompletedFlightsWidget());

    var ws = tester.allWidgets;
    var findIcon = (IconData i) =>
        ws.where((w) => w is Icon).where((w) => (w as Icon).icon == i);
    expect(findIcon(Icons.check), hasLength(1));
    expect(findIcon(Icons.error), hasLength(1));
    expect(findIcon(Icons.cancel), hasLength(1));
  });*/

  testWidgets("UserRequestsWidget shows Reject icon",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    var deleteButton = find.byKey(Key("reject-icon-3"));
    expect(deleteButton, findsOneWidget);
  });

  testWidgets("UserRequestsWidget shows alert when deleting",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    var rejectButton = find.byKey(Key("reject-icon-3"));
    expect(find.text("¿Realmente quiere Rechazar la solicitud?"), findsNothing);
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();
    expect(
        find.text("¿Realmente quiere Rechazar la solicitud?"), findsOneWidget);

    await tester.tap(find.text("No"));
    await tester.pumpAndSettle();
    expect(find.text("¿Realmente quiere Rechazar la solicitud?"), findsNothing);
  });

  testWidgets("UserRequestsWidget rejects request",
      (WidgetTester tester) async {
    when(client.patch(any,
            headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response("", 200));
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    var rejectButton = find.byKey(Key("reject-icon-3"));
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Sí"));
    await tester.pumpAndSettle();

    var verifier = verify(client.patch(captureAny,
        headers: captureAnyNamed("headers"), body: captureAnyNamed("body")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/users/3/");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
    expect(jsonDecode(verifier.captured[2]), containsPair("type", "DELETED"));
  });

  testWidgets("UserRequestsWidget shows snackbar if reject fails",
      (WidgetTester tester) async {
    when(client.patch(any,
            headers: anyNamed("headers"), body: anyNamed("body")))
        .thenThrow(SocketException("dummy"));
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    var rejectButton = find.byKey(Key("reject-icon-3"));
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.text("Sí"));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text("Error al configurar usuario"), findsOneWidget);
  });

  testWidgets("UserRequestsWidget shows Accept icon",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    var acceptButton = find.byKey(Key("accept-icon-3"));
    expect(acceptButton, findsOneWidget);
  });

  testWidgets("UserRequestsWidget accepts request",
      (WidgetTester tester) async {
    when(client.patch(any,
            headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response("", 200));
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    var acceptButton = find.byKey(Key("accept-icon-3"));
    await tester.tap(acceptButton);
    await tester.pumpAndSettle();

    var verifier = verify(client.patch(captureAny,
        headers: captureAnyNamed("headers"), body: captureAnyNamed("body")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/users/3/");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
    expect(jsonDecode(verifier.captured[2]), containsPair("type", "ACTIVE"));
  });

  testWidgets("UserRequestsWidget shows snackbar if accept fails",
      (WidgetTester tester) async {
    when(client.patch(any,
            headers: anyNamed("headers"), body: anyNamed("body")))
        .thenThrow(SocketException("dummy"));
    await pumpArgumentWidget(tester, args: null, child: UserRequestsWidget());

    var acceptButton = find.byKey(Key("accept-icon-3"));
    await tester.tap(acceptButton);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text("Error al configurar usuario"), findsOneWidget);
  });

  testWidgets("routeNameFunc() returns correct route",
      (WidgetTester tester) async {
    expect(UserRequestsWidget().routeNameFunc(), "/user/");
  });
}
