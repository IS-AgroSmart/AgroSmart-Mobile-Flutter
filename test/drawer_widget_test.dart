import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/deleted_flights_widget.dart';
import 'package:flutter_app/drawer.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/login_widget.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/new_flight.dart';
import 'package:flutter_app/processing_flights_widget.dart';
import 'package:flutter_app/waiting_flights_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.dart';

void main() {
  SharedPreferences.setMockInitialValues(
      {"token": "faketoken", "username": "foo"});
  Helpers.loggedInUser = User(
      pk: 1,
      username: "myusername",
      name: "myname",
      email: "email@example.com",
      isStaff: false,
      type: "ADMIN");

  var widget, mockObserver, client;

  setUp(() {
    mockObserver = MockNavigatorObserver();
    widget = MaterialApp(home: AppDrawer(), navigatorObservers: [
      mockObserver
    ], routes: {
      NewFlightWidget.routeName: (context) => NewFlightWidget(),
      CompletedFlightsWidget.routeName: (context) => CompletedFlightsWidget(),
      ProcessingFlightsWidget.routeName: (context) => ProcessingFlightsWidget(),
      WaitingFlightsWidget.routeName: (context) => WaitingFlightsWidget(),
      DeletedFlightsWidget.routeName: (context) => DeletedFlightsWidget(),
      LoginWidget.routeName: (context) => LoginWidget(),
    });

    client = MockClient();
    Api.client = client;
    when(client.get(any,
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode([]), 200));
  });

  testWidgets('Drawer has a title and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    expect(find.text("Crear nuevo vuelo"), findsOneWidget);
    expect(find.text("Vuelos completos"), findsOneWidget);
    expect(find.text("Cerrar sesión"), findsOneWidget);
  });

  testWidgets('Drawer shows user email', (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    expect(find.text(Helpers.loggedInUser.email), findsOneWidget);
  });

  testWidgets("Drawer navigates to Create Flight", (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(NewFlightWidget), findsNothing);
    await tester.tap(find.text("Crear nuevo vuelo"));
    await tester.pumpAndSettle();
    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(NewFlightWidget), findsOneWidget);
  });

  testWidgets("Drawer navigates to Completed Flights",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(CompletedFlightsWidget), findsNothing);
    await tester.tap(find.text("Vuelos completos"));
    await tester.pumpAndSettle();
    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(CompletedFlightsWidget), findsOneWidget);
  });

  testWidgets("Drawer navigates to Processing Flights",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(ProcessingFlightsWidget), findsNothing);
    await tester.tap(find.text("Vuelos en procesamiento"));
    await tester.pumpAndSettle();
    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(ProcessingFlightsWidget), findsOneWidget);
  });

  testWidgets("Drawer navigates to Waiting Flights",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(WaitingFlightsWidget), findsNothing);
    await tester.tap(find.text("Vuelos pendientes"));
    await tester.pumpAndSettle();
    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(WaitingFlightsWidget), findsOneWidget);
  });

  testWidgets("Drawer navigates to Deleted Flights",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(DeletedFlightsWidget), findsNothing);
    await tester.tap(find.text("Vuelos eliminados"));
    await tester.pumpAndSettle();
    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(DeletedFlightsWidget), findsOneWidget);
  });
}
