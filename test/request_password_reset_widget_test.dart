import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/password_reset_requested_widget.dart';
import 'package:flutter_app/request_password_reset_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'mocks.dart';

void main() {
  var widget, mockObserver;
  setUp(() {
    mockObserver = MockNavigatorObserver();
    widget = MaterialApp(
      home: RequestPasswordResetWidget(),
      navigatorObservers: [mockObserver],
      routes: {
        PasswordResetRequestedWidget.routeName: (context) =>
            PasswordResetRequestedWidget(),
      },
    );
  });

  testWidgets('RequestPasswordResetWidget has a title and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    final titleFinder = find.byType(RaisedButton);
    expect(titleFinder, findsOneWidget);
    expect(find.text("Recuperar Contraseña"),
        findsOneWidget); // Title and button text
    expect(find.byType(RaisedButton), findsOneWidget);
  });

  testWidgets("RequestPasswordResetWidget has single text field",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets(
      "RequestPasswordResetWidget sends API request when all data passed",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    var client = MockClient();
    Api.client = client;
    when(client.post(any, body: anyNamed("body")))
        .thenAnswer((_) async => http.Response(jsonEncode({}), 200));

    await tester.enterText(
        find.byType(TextFormField).first, "myemail@example.com");
    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();

    var verifier = verify(client.post(
        "http://droneapp.ngrok.io/api/password_reset/",
        body: captureAnyNamed("body")));
    expect(
        verifier.captured.single, containsPair("email", "myemail@example.com"));
    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(PasswordResetRequestedWidget), findsOneWidget);
  });

  testWidgets(
      "RequestPasswordResetWidget shows error message when API returns error",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var client = MockClient();
    Api.client = client;
    when(client.post(any, body: anyNamed("body")))
        .thenAnswer((_) async => http.Response(jsonEncode({}), 500));

    await tester.enterText(
        find.byType(TextFormField).first, "myemail@example.com");
    await tester.tap(find.byType(RaisedButton));
    await tester.pump();

    expect(
        find.text("Error al solicitar reseteo de contraseña"), findsOneWidget);
  });

  testWidgets(
      "RequestPasswordResetWidget shows error message when SocketException",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var client = MockClient();
    Api.client = client;
    when(client.post(any, body: anyNamed("body")))
        .thenThrow(new SocketException("dummy"));

    await tester.enterText(
        find.byType(TextFormField).first, "myemail@example.com");
    await tester.tap(find.byType(RaisedButton));
    await tester.pump();

    expect(
        find.text("Error al solicitar reseteo de contraseña"), findsOneWidget);
  });
}
