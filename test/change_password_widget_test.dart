import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/change_password.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.dart';

void main() {
  SharedPreferences.setMockInitialValues(
      {"token": "faketoken", "username": "foo"});
  Helpers.loggedInUser = User(
      pk: 2,
      username: "notdemo",
      name: "Not Demo User",
      email: "notdemo@example.com",
      organization: "Acme Corp",
      isStaff: false,
      type: "ACTIVE");
  var widget, mockObserver;
  setUp(() {
    mockObserver = MockNavigatorObserver();
    widget = MaterialApp(home: ChangePassword(), navigatorObservers: [
      mockObserver
    ], routes: {
      Profile.routeName: (context) => Profile(),
    });
  });

  testWidgets('ChangePasswordWidget has a title and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    final titleFinder = find.byType(RaisedButton);
    expect(titleFinder, findsNWidgets(2));
    expect(find.text("Cambiar contraseña"), findsOneWidget);
    expect(find.byType(RaisedButton), findsNWidgets(2));
  });

  testWidgets('ChangePasswordWidget has two text fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var finder = find.byType(TextFormField);
    expect(finder, findsNWidgets(2));
    expect(
        find.descendant(
            of: finder.first, matching: find.text("Nueva Contraseña")),
        findsOneWidget);
    expect(
        find.descendant(
            of: finder.last, matching: find.text("Repetir Contraseña Nueva")),
        findsOneWidget);
  });

  testWidgets("ChangePasswordWidget sends new pass to API",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    await tester.enterText(find.byType(TextFormField).first, "mypassword");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    var client = MockClient();
    Api.client = client;
    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response(jsonEncode({}), 200));

    await tester.tap(find.byType(RaisedButton).first);
    await tester.pump();

    var verifier = verify(client.post(any,
        headers: captureAnyNamed("headers"), body: captureAnyNamed("body")));
    expect(verifier.captured[1], containsPair("password", "mypassword"));
  });

  testWidgets("ChangePasswordWidget handles correct reset ",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    var client = MockClient();
    Api.client = client;
    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async =>
            http.Response(jsonEncode({"token": "mynewtoken"}), 200));

    await tester.enterText(find.byType(TextFormField).first, "mypassword");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    await tester.tap(find.byType(RaisedButton).first);
    await tester.pumpAndSettle();

    verify(client.post(any,
            headers: anyNamed("headers"), body: anyNamed("body")))
        .called(1);
    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(Profile), findsOneWidget);
  });

  testWidgets("ChangePasswordWidget handles incorrect password change",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var client = MockClient();
    Api.client = client;
    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response(
            jsonEncode({
              "password": ["too boring"]
            }),
            400));

    await tester.enterText(find.byType(TextFormField).first, "mypassword");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    await tester.tap(find.byType(RaisedButton).first);
    await tester.pump();

    verify(client.post(any,
            headers: anyNamed("headers"), body: anyNamed("body")))
        .called(1);
    expect(find.text("password: too boring"), findsOneWidget);
  });

  testWidgets("ChangePasswordWidget shows error message on exception",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var client = MockClient();
    Api.client = client;
    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
        .thenThrow(new SocketException("dummy"));

    await tester.enterText(find.byType(TextFormField).first, "mypassword");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    await tester.tap(find.byType(RaisedButton).first);
    await tester.pump();

    expect(find.text("Error de conexión"), findsOneWidget);
  });

  testWidgets("ChangePasswordWidget doesn't call API if password missing",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    expect(find.text("Contraseñas no coinciden"), findsNothing);
    expect(find.text("Escriba una contraseña válida"), findsNothing);

    var client = MockClient();
    Api.client = client;

    await tester.tap(find.byType(RaisedButton).first);
    await tester.pump();
    expect(find.text("Contraseñas no coinciden"), findsOneWidget);
    expect(find.text("Escriba una contraseña válida"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, "mypass");
    await tester.tap(find.byType(RaisedButton).first);
    await tester.pump();
    expect(find.text("Escriba una contraseña válida"), findsNothing);
    expect(find.text("Contraseñas no coinciden"), findsOneWidget);

    verifyNever(client.post(any));
  });

  testWidgets("ChangePasswordWidget goes back on Cancel",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    await tester.tap(find.byType(RaisedButton).last);
    await tester.pumpAndSettle();

    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(Profile), findsOneWidget);
  });
}
