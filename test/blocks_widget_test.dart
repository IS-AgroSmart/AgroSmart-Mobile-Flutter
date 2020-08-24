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
          NewBlockWidget.routeName: (context) => NewBlockWidget(),
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

  testWidgets("BlocksWidget has correct title & FAB",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());

    expect(find.text("Criterios de Bloqueo"), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  void assertFindsText(Finder widget, String text) {
    expect(
        find.descendant(of: widget, matching: find.text(text)), findsOneWidget);
  }

  testWidgets("BlocksWidget shows all block criteria",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());

    var tiles = find.byType(ListTile);
    expect(tiles, findsNWidgets(4));
    assertFindsText(tiles.at(0), "Si el DOMAIN es igual a:");
    assertFindsText(tiles.at(0), "DOMAIN: spam.ru");
    assertFindsText(tiles.at(1), "Si el EMAIL es igual a:");
    assertFindsText(tiles.at(1), "EMAIL: spammer@gmail.com");
    assertFindsText(tiles.at(2), "Si el IP es igual a:");
    assertFindsText(tiles.at(2), "IP: 192.168.100.100");

    var verifier =
        verify(client.get(captureAny, headers: captureAnyNamed("headers")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/block_criteria");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("BlocksWidget shows Delete icon", (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());

    var deleteButton = find.byKey(Key("icon2-criteria-3"));
    expect(deleteButton, findsOneWidget);
  });

  testWidgets("BlocksWidget shows alert when deleting",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());

    var deleteButton = find.byKey(Key("icon2-criteria-3"));
    expect(find.text("¿Realmente quiere Eliminar el criterio?"), findsNothing);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(
        find.text("¿Realmente quiere Eliminar el criterio?"), findsOneWidget);

    await tester.tap(find.text("No"));
    await tester.pumpAndSettle();
    expect(find.text("¿Realmente quiere Eliminar el criterio?"), findsNothing);
  });

  testWidgets("BlocksWidget deletes criteria", (WidgetTester tester) async {
    when(client.delete(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("", 204));
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());

    var deleteButton = find.byKey(Key("icon2-criteria-3"));
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Sí"));
    await tester.pumpAndSettle();

    var verifier =
        verify(client.delete(captureAny, headers: captureAnyNamed("headers")));
    expect(
        verifier.captured[0], "http://droneapp.ngrok.io/api/block_criteria/3/");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });

  testWidgets("BlocksWidget shows snackbar if delete fails",
      (WidgetTester tester) async {
    when(client.delete(any, headers: anyNamed("headers")))
        .thenThrow(SocketException("dummy"));
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());

    var deleteButton = find.byKey(Key("icon2-criteria-3"));
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.text("Sí"));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text("Error al eliminar criterio de bloqueo"), findsOneWidget);
  });

  testWidgets("BlocksWidget doesn't show Accept icon",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());

    var acceptButton = find.byKey(Key("icon1-criteria-3"));
    expect(acceptButton, findsNothing);
  });

  testWidgets("Clicking on FAB navigates to New Criteria",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    verify(mockObserver.didPush(any, any));
    expect(find.byType(NewBlockWidget), findsOneWidget);
  });

  testWidgets("BlocksWidget searches for criteria",
      (WidgetTester tester) async {
    when(client.delete(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("", 204));
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());
    expect(find.text("DOMAIN: spam.ru"), findsOneWidget);
    expect(find.text("EMAIL: spammer@gmail.com"), findsOneWidget);
    expect(find.text("IP: 192.168.100.100"), findsOneWidget);
    expect(find.text("USER_NAME: spammyusername"), findsOneWidget);

    var searchField = find.byType(TextFormField);
    var searchButton =
        find.descendant(of: searchField, matching: find.byType(IconButton));
    expect(searchButton, findsOneWidget);
    await tester.enterText(searchField, "spamm");
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    expect(find.text("DOMAIN: spam.ru"), findsNothing);
    expect(find.text("EMAIL: spammer@gmail.com"), findsOneWidget);
    expect(find.text("IP: 192.168.100.100"), findsNothing);
    expect(find.text("USER_NAME: spammyusername"), findsOneWidget);
  });

  testWidgets("BlocksWidget shows message when empty array",
      (WidgetTester tester) async {
    reset(client);
    when(client.get("http://droneapp.ngrok.io/api/block_criteria",
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode([]), 200));
    await pumpArgumentWidget(tester, args: null, child: BlocksWidget());

    expect(find.text("No hay criterios de bloqueo"), findsOneWidget);
  });

  test("BlocksWidget has the correct route name", () {
    expect(BlocksWidget().routeNameFunc(), "/blocks/");
  });
}
