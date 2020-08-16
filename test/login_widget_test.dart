import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/create_account_widget.dart';
import 'package:flutter_app/login_widget.dart';
import 'package:flutter_app/request_password_reset_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'mocks.dart';

void main() {
  var widget, mockObserver;
  setUp(() {
    mockObserver = MockNavigatorObserver();

    final key = GlobalKey<NavigatorState>();
    widget = MaterialApp(
      home: LoginWidget(),
      navigatorKey: key,
      navigatorObservers: [mockObserver],
      routes: {
        CreateAccountWidget.routeName: (context) => CreateAccountWidget(),
        RequestPasswordResetWidget.routeName: (context) =>
            RequestPasswordResetWidget()
      },
    );
  });

  testWidgets('LoginWidget has a title and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    final titleFinder = find.byType(RaisedButton);
    expect(titleFinder, findsOneWidget);
    expect(
        find.text("Iniciar sesión"), findsNWidgets(2)); // Title and button text
    expect(find.byType(RaisedButton), findsOneWidget);
    expect(find.byType(InkWell), findsWidgets);
  });

  testWidgets('LoginWidget has two text fields', (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var finder = find.byType(TextFormField);
    expect(finder, findsNWidgets(2));
    expect(find.descendant(of: finder.first, matching: find.text("Username")),
        findsOneWidget);
    expect(find.descendant(of: finder.last, matching: find.text("Contraseña")),
        findsOneWidget);

    expect(find.text("Credenciales erróneas!"), findsNothing);
  });

  testWidgets("LoginWidget sends credentials to API",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    await tester.enterText(find.byType(TextFormField).first, "myusername");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    var client = MockClient();
    Api.client = client;
    when(client.post(any, body: anyNamed("body")))
        .thenAnswer((_) async => http.Response(jsonEncode({}), 200));

    await tester.tap(find.byType(RaisedButton));
    await tester.pump();

    var verifier = verify(client.post(any, body: captureAnyNamed("body")));
    expect(verifier.captured.single, containsPair("username", "myusername"));
    expect(verifier.captured.single, containsPair("password", "mypassword"));
  });

  testWidgets("LoginWidget handles correct login", (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var client = MockClient();
    Api.client = client;
    when(client.post(any, body: anyNamed("body"))).thenAnswer(
        (_) async => http.Response(jsonEncode({"token": "mynewtoken"}), 200));

    await tester.enterText(find.byType(TextFormField).first, "myusername");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    await tester.tap(find.byType(RaisedButton));
    await tester.pump();

    expect(find.text("Credenciales erróneas!"), findsNothing);
    verify(client.post(any, body: anyNamed("body"))).called(1);
  });

  testWidgets("LoginWidget handles incorrect login",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var client = MockClient();
    Api.client = client;
    when(client.post(any, body: anyNamed("body")))
        .thenAnswer((_) async => http.Response(jsonEncode({}), 400));

    await tester.enterText(find.byType(TextFormField).first, "myusername");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    await tester.tap(find.byType(RaisedButton));
    await tester.pump();

    verify(client.post(any, body: anyNamed("body"))).called(1);
    expect(find.text("Credenciales erróneas!"), findsOneWidget);
  });

  testWidgets("LoginWidget doesn't call API if username or password missing",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    expect(find.text("Escriba un nombre de usuario"), findsNothing);
    expect(find.text("Escriba una contraseña"), findsNothing);

    var client = MockClient();
    Api.client = client;

    await tester.tap(find.byType(RaisedButton));
    await tester.pump();
    expect(find.text("Escriba un nombre de usuario"), findsOneWidget);
    expect(find.text("Escriba una contraseña"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, "myusername");
    await tester.tap(find.byType(RaisedButton));
    await tester.pump();
    expect(find.text("Escriba un nombre de usuario"), findsNothing);
    expect(find.text("Escriba una contraseña"), findsOneWidget);

    verifyNever(client.post(any));
  });

  testWidgets("LoginWidget navigates to Create Account",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(CreateAccountWidget), findsNothing);
    var newAccountButton = find.widgetWithText(InkWell, "Crear cuenta");
    expect(newAccountButton, findsOneWidget);
    await tester.tap(newAccountButton);
    await tester.pumpAndSettle();

    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(CreateAccountWidget), findsOneWidget);
  });

  testWidgets("LoginWidget navigates to Forgot Password",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(RequestPasswordResetWidget), findsNothing);
    var newAccountButton = find.widgetWithText(InkWell, "Olvidé mi contraseña");
    expect(newAccountButton, findsOneWidget);
    await tester.tap(newAccountButton);
    await tester.pumpAndSettle();

    verify(mockObserver.didPush(any, any));
    expect(find.byType(RequestPasswordResetWidget), findsOneWidget);
  });
}
