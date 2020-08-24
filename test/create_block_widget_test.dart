import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/blocks_widget.dart';
import 'package:flutter_app/create_block_widget.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/models/user.dart';
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
    {"pk": 1, "type": "DOMAIN", "ip": "", "value": "spam.ru"},
    {"pk": 3, "type": "EMAIL", "ip": "", "value": "spammer@gmail.com"},
    {"pk": 10, "type": "IP", "ip": "192.168.100.100", "value": null},
    {"pk": 4, "type": "USER_NAME", "ip": "", "value": "spammyusername"},
  ];

  setUp(() {
    mockObserver = MockNavigatorObserver();
    client = MockClient();
    Api.client = client;
    when(client.get("http://droneapp.ngrok.io/api/block_criteria",
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
          BlocksWidget.routeName: (context) => BlocksWidget(),
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

  testWidgets("NewBlockWidget has correct title and button",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: NewBlockWidget());

    expect(find.text("Crear Criterio de Bloqueo"), findsNWidgets(2));
    expect(find.byType(RaisedButton), findsOneWidget);
  });

  Future<void> _tapOption(
      WidgetTester tester, Finder dropdown, String option) async {
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> _fillAndSend(WidgetTester tester, String type) async {
    await pumpArgumentWidget(tester, args: null, child: NewBlockWidget());

    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response(jsonEncode({}), 201));

    await _tapOption(tester, find.byKey(Key("type-dropdown")), type);
    await tester.enterText(find.byType(TextFormField).first, "my.fake.field");

    await tester.tap(find.byType(RaisedButton));
    await tester.pump();
  }

  testWidgets("NewBlockWidget sends API request when all data passed (IP)",
      (WidgetTester tester) async {
    await _fillAndSend(tester, "IP");

    var verifier = verify(client.post(
        "http://droneapp.ngrok.io/api/block_criteria/",
        headers: captureAnyNamed("headers"),
        body: captureAnyNamed("body")));
    expect(
        verifier.captured[0], containsPair("Authorization", "Token faketoken"));
    expect(verifier.captured[1], containsPair("type", "IP"));
    expect(verifier.captured[1], containsPair("ip", "my.fake.field"));
    expect(verifier.captured[1], containsPair("value", ""));
  });

  testWidgets("NewBlockWidget sends API request when all data passed (domain)",
      (WidgetTester tester) async {
    await _fillAndSend(tester, "DOMAIN");

    var verifier = verify(client.post(
        "http://droneapp.ngrok.io/api/block_criteria/",
        headers: captureAnyNamed("headers"),
        body: captureAnyNamed("body")));
    expect(
        verifier.captured[0], containsPair("Authorization", "Token faketoken"));
    expect(verifier.captured[1], containsPair("type", "DOMAIN"));
    expect(verifier.captured[1], containsPair("ip", ""));
    expect(verifier.captured[1], containsPair("value", "my.fake.field"));
  });

  testWidgets("NewBlockWidget shows error message when API returns error",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: NewBlockWidget());

    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response("", 400));

    await _tapOption(tester, find.byKey(Key("type-dropdown")), "IP");
    await tester.enterText(find.byType(TextFormField).first, "my.fake.ip");

    expect(find.text("Error al crear criterio!"), findsNothing);
    await tester.tap(find.byType(RaisedButton));
    await tester.pump();

    expect(find.text("Error al crear criterio!"), findsOneWidget);
  });

//  testWidgets("NewBlockWidget shows error message when SocketException",
//      (WidgetTester tester) async {
//    await pumpArgumentWidget(tester, args: null, child: NewBlockWidget());
//
//    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
//        .thenThrow(new SocketException("dummy"));
//
//    await _tapOption(tester, find.byKey(Key("type-dropdown")), "IP");
//    await tester.enterText(find.byType(TextFormField).first, "my.fake.ip");
//
//    expect(find.text("Error al crear criterio!"), findsNothing);
//    await tester.tap(find.byType(RaisedButton));
//    await tester.pump();
//
//    expect(find.text("Error al crear criterio!"), findsOneWidget);
//  });

  test("NewBlockWidget has the correct route name", () {
    expect(NewBlockWidget.routeName, "/blocks/new");
  });
}
