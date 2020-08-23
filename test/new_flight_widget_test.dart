import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/new_flight.dart';
import 'package:flutter_app/waiting_flights_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();
  SharedPreferences.setMockInitialValues(
      {"token": "faketoken", "username": "foo"});

  var widget, client, mockObserver;
  setUp(() {
    Helpers.loggedInUser = User(
        pk: 1,
        username: "admin",
        name: "admin",
        email: "admin@example.com",
        isStaff: false,
        type: "ADMIN");

    mockObserver = MockNavigatorObserver();
    client = MockClient();
    Api.client = client;

    widget = MaterialApp(
      home: NewFlightWidget(),
      navigatorObservers: [mockObserver],
      routes: {
        WaitingFlightsWidget.routeName: (context) => WaitingFlightsWidget()
      },
    );
  });

  testWidgets('NewFlightWidget has a title and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    final titleFinder = find.byType(RaisedButton);
    expect(titleFinder, findsOneWidget);
    expect(find.text("Crear vuelo"), findsNWidgets(2)); // Title and button text
    expect(find.byType(RaisedButton), findsOneWidget);
  });

  testWidgets('NewFlightWidget has a dropdown with the two cameras',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    final dropdownFinder = find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<Camera>);
    expect(dropdownFinder, findsOneWidget);
    expect(find.descendant(of: dropdownFinder, matching: find.text("RGB")),
        findsOneWidget);
    expect(
        find.descendant(of: dropdownFinder, matching: find.text("Micasense")),
        findsOneWidget);
  });

  testWidgets('NewFlightWidget needs a flight name',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    expect(find.text("Escriba un nombre para el vuelo"), findsNothing);

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
    expect(find.text("Escriba un nombre para el vuelo"), findsOneWidget);
  });

  testWidgets('NewFlightWidget needs a description',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    await tester.enterText(find.byType(TextFormField).first, "foo");

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
    expect(find.text("Escriba un nombre para el vuelo"), findsNothing);
    expect(find.text("Escriba una descripción"), findsOneWidget);
  });

  testWidgets('NewFlightWidget needs a camera', (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    await tester.enterText(find.byType(TextFormField).first, "foo");
    await tester.enterText(find.byType(TextFormField).last, "descr");

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
    expect(find.text("Escriba un nombre para el vuelo"), findsNothing);
    expect(find.text("Escriba una descripción"), findsNothing);
    expect(find.text("Seleccione una cámara"), findsWidgets);
  });

  testWidgets('NewFlightWidget needs a date', (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    await tester.enterText(find.byType(TextFormField).first, "foo");
    await tester.enterText(find.byType(TextFormField).last, "descr");
    var cameraDropdown = find.byKey(Key("camera-dropdown"));
    expect(cameraDropdown, findsOneWidget);
    await tester.tap(cameraDropdown);
    await tester.pumpAndSettle();
    await tester.tap(
        find.descendant(of: cameraDropdown, matching: find.text("Micasense")));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
    expect(find.text("Escriba un nombre para el vuelo"), findsNothing);
    expect(find.text("Escriba una descripción"), findsNothing);
    expect(find.text("Seleccione una cámara"), findsNothing);
    expect(find.text("Seleccione una fecha"), findsOneWidget);
  });

  Future<void> _fillAll(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, "foo");
    await tester.enterText(find.byType(TextFormField).last, "descr");
    var cameraDropdown = find.byKey(Key("camera-dropdown"));
    expect(cameraDropdown, findsOneWidget);
    await tester.tap(cameraDropdown);
    await tester.pumpAndSettle();
    await tester.tap(
        find.descendant(of: cameraDropdown, matching: find.text("Micasense")));
    await tester.pumpAndSettle();
    expect(find.text("OK"), findsNothing);
    await tester.tap(find.byType(DateTimeField));
    await tester.pumpAndSettle();
    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
  }

  testWidgets('Pressing Create button sends API request',
      (WidgetTester tester) async {
    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response("", 201));
    when(client.get(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("[]", 200));
    await tester.pumpWidget(widget);

    await _fillAll(tester);

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
    var verifier = verify(client.post(captureAny,
        headers: captureAnyNamed("headers"), body: captureAnyNamed("body")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/flights/");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
    expect(verifier.captured[2], containsPair("name", "foo"));

    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(WaitingFlightsWidget), findsOneWidget);
  });

  testWidgets('Shows error message when API request fails',
      (WidgetTester tester) async {
    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response("", 400));
    await tester.pumpWidget(widget);

    await _fillAll(tester);

    expect(find.text("Error al crear vuelo!"), findsNothing);
    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
    expect(find.text("Error al crear vuelo!"), findsOneWidget);
  });
}
