import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/create_account_successful_widget.dart';
import 'package:flutter_app/create_account_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'mocks.dart';

void main() {
  var widget;
  setUp(() {
    widget = MaterialApp(
      home: CreateAccountWidget(),
      routes: {
        CreateAccountSuccessfulWidget.routeName: (context) =>
            CreateAccountSuccessfulWidget(),
      },
    );
  });

  testWidgets('CreateAccountWidget has a title and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    final titleFinder = find.byType(RaisedButton);
    expect(titleFinder, findsOneWidget);
    expect(
        find.text("Crear cuenta"), findsNWidgets(2)); // Title and button text
    expect(find.byType(RaisedButton), findsOneWidget);
  });

  testWidgets("CreateAccountWidget sends API request when all data passed",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var client = MockClient();
    Api.client = client;
    when(client.post(any, body: anyNamed("body")))
        .thenAnswer((_) async => http.Response(jsonEncode({}), 201));

    await tester.enterText(find.byType(TextFormField).first, "myusername");
    await tester.enterText(
        find.byType(TextFormField).at(1), "myemail@example.com");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    await tester.tap(find.byType(RaisedButton));
    await tester.pump();

    var verifier = verify(client.post("http://droneapp.ngrok.io/api/users/",
        body: captureAnyNamed("body")));
    expect(verifier.captured.single, containsPair("username", "myusername"));
    expect(
        verifier.captured.single, containsPair("email", "myemail@example.com"));
    expect(verifier.captured.single, containsPair("password", "mypassword"));
  });

  testWidgets("CreateAccountWidget shows error message when API returns error",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var client = MockClient();
    Api.client = client;
    when(client.post(any, body: anyNamed("body")))
        .thenAnswer((_) async => http.Response(
            jsonEncode({
              "username": ["en uso"]
            }),
            400));

    await tester.enterText(find.byType(TextFormField).first, "myusername");
    await tester.enterText(
        find.byType(TextFormField).at(1), "myemail@example.com");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    await tester.tap(find.byType(RaisedButton));
    await tester.pump();

    expect(find.text("username: en uso"), findsOneWidget);
  });

  testWidgets("CreateAccountWidget shows error message when SocketException",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    var client = MockClient();
    Api.client = client;
    when(client.post(any, body: anyNamed("body")))
        .thenThrow(new SocketException("dummy"));

    await tester.enterText(find.byType(TextFormField).first, "myusername");
    await tester.enterText(
        find.byType(TextFormField).at(1), "myemail@example.com");
    await tester.enterText(find.byType(TextFormField).last, "mypassword");

    await tester.tap(find.byType(RaisedButton));
    await tester.pump();

    expect(find.text("Error de conexión"), findsOneWidget);
  });
}
