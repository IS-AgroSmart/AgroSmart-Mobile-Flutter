import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/user_requests.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/deleted_flights_widget.dart';
import 'package:flutter_app/drawer.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/login_widget.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/new_flight.dart';
import 'package:flutter_app/processing_flights_widget.dart';
import 'package:flutter_app/profile.dart';
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
      Profile.routeName: (context) => Profile(),
      UserRequestsWidget.routeName: (context) => UserRequestsWidget(),
    });

    client = MockClient();
    Api.client = client;
    when(client.get(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode([]), 200));
  });

  testWidgets('Drawer has a title and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    expect(find.text("Vuelos completos"), findsOneWidget);

    // HACK: Have to drag down to expose Logout button!
    await tester.drag(find.text("Vuelos completos"), Offset(0.0, -200));
    await tester.pump();
    expect(find.text("Cerrar sesión"), findsOneWidget);
  });

  testWidgets("Drawer shows New Flight if user is not demo",
      (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "notdemo",
        name: "Not Demo User",
        email: "notdemo@example.com",
        isStaff: false,
        type: "ACTIVE");
    await tester.pumpWidget(widget);

    expect(find.text("Crear nuevo vuelo"), findsOneWidget);
  });

  testWidgets("Drawer doesn't show New Flight if user is demo",
      (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "demo",
        name: "Demo User",
        email: "demo@example.com",
        isStaff: false,
        type: "DEMO_USER");
    await tester.pumpWidget(widget);

    expect(find.text("Crear nuevo vuelo"), findsNothing);
  });

  testWidgets('Drawer shows user email', (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    expect(find.text(Helpers.loggedInUser.email), findsOneWidget);
  });

  testWidgets("Drawer navigates to Create Flight", (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "notdemo",
        name: "Not Demo User",
        email: "notdemo@example.com",
        isStaff: false,
        type: "ACTIVE");
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

  testWidgets("Drawer closes account", (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(DeletedFlightsWidget), findsNothing);
    await tester.drag(find.text("Vuelos completos"), Offset(0.0, -200));
    await tester.pump();
    await tester.tap(find.text("Cerrar sesión"));
    await tester.pumpAndSettle();
    verify(mockObserver.didPush(any, any));
    verify(mockObserver.didRemove(any, any));
    expect(find.byType(LoginWidget), findsOneWidget);
  });

  testWidgets("Drawer navigates to profile", (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "demo",
        name: "Demo User",
        email: "demo@example.com",
        organization: "Acme Corp",
        isStaff: false,
        type: "DEMO_USER");
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(DeletedFlightsWidget), findsNothing);
    await tester.drag(find.text("Vuelos completos"), Offset(0.0, -200));
    await tester.pump();
    await tester.tap(find.text("Perfil"));
    await tester.pumpAndSettle();
    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(Profile), findsOneWidget);
  });

  /*testWidgets("Drawer navigates to admin options", (WidgetTester tester) async {
    Helpers.loggedInUser = User(
        pk: 2,
        username: "admin",
        name: "Admin User",
        email: "admin@example.com",
        organization: "Acme Corp",
        isStaff: false,
        type: "ADMIN");
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    var client = MockClient();
    Api.client = client;
    when(client.get(any, headers: anyNamed("headers")))
        .thenAnswer((_) async =>
        http.Response(jsonEncode([]), 200));

    expect(find.byType(UserRequestsWidget), findsNothing);
    await tester.drag(find.text("Vuelos completos"), Offset(0.0, -200));
    await tester.pump();
    await tester.tap(find.text("Opciones Admin"));
    await tester.pumpAndSettle();
    verify(mockObserver.didPush(any, any));
    verify(mockObserver.didRemove(any, any));
    expect(find.byType(UserRequestsWidget), findsOneWidget);
  });*/
}
