import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_app/new_flight.dart';
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

  var widget, client;
  setUp(() {
    client = MockClient();
    Api.client = client;

    widget = MaterialApp(home: NewFlightWidget());
  });

  testWidgets('NewFlightWidget has a title and buttons',
          (WidgetTester tester) async {
        await tester.pumpWidget(widget);

        final titleFinder = find.byType(RaisedButton);
        expect(titleFinder, findsOneWidget);
        expect(find.text("Crear vuelo"),
            findsNWidgets(2)); // Title and button text
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
            find.descendant(
                of: dropdownFinder, matching: find.text("Micasense")),
            findsOneWidget);
      });

  testWidgets('NewFlightWidget needs a flight name',
          (WidgetTester tester) async {
        when(client.get(any, headers: anyNamed("headers")))
            .thenAnswer((_) async => http.Response("", 200));
        await tester.pumpWidget(widget);
        expect(find.text("Escriba un nombre para el vuelo"), findsNothing);

        await tester.tap(find.byType(RaisedButton));
        await tester.pumpAndSettle();
        expect(find.text("Escriba un nombre para el vuelo"), findsOneWidget);
      });

  testWidgets('NewFlightWidget needs a description',
          (WidgetTester tester) async {
        when(client.get(any, headers: anyNamed("headers")))
            .thenAnswer((_) async => http.Response("", 200));
        await tester.pumpWidget(widget);
        await tester.enterText(find
            .byType(TextFormField)
            .first, "foo");

        await tester.tap(find.byType(RaisedButton));
        await tester.pumpAndSettle();
        expect(find.text("Escriba un nombre para el vuelo"), findsNothing);
        expect(find.text("Escriba una descripción"), findsOneWidget);
      });

  testWidgets('NewFlightWidget needs a camera', (WidgetTester tester) async {
    when(client.get(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("", 200));
    await tester.pumpWidget(widget);
    await tester.enterText(find
        .byType(TextFormField)
        .first, "foo");
    await tester.enterText(find
        .byType(TextFormField)
        .last, "descr");

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
    expect(find.text("Escriba un nombre para el vuelo"), findsNothing);
    expect(find.text("Escriba una descripción"), findsNothing);
    expect(find.text("Seleccione una cámara"), findsWidgets);
  });

  /*testWidgets('NewFlightWidget needs a date', (WidgetTester tester) async {
    when(client.get(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("", 200));
    await tester.pumpWidget(widget);
    await tester.enterText(find
        .byType(TextFormField)
        .first, "foo");
    await tester.enterText(find
        .byType(TextFormField)
        .last, "descr");
    var state = tester.state<NewFlightFormState>(find.byType(NewFlightForm));
    state.camera =    Camera.MICASENSE;
    state.trigger()

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
    expect(find.text("Escriba un nombre para el vuelo"), findsNothing);
    expect(find.text("Escriba una descripción"), findsNothing);
    expect(find.text("Seleccione una cámara"), findsNothing);
    expect(find.text("Seleccione una fecha"), findsOneWidget);
  });*/

  /*testWidgets('Pressing Create button sends API request',
      (WidgetTester tester) async {
    when(client.get(any, headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response("", 200));
    await tester.pumpWidget(widget);
    await tester.enterText(find.byType(TextFormField).first, "foo");

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();

    expect(find.text("Escriba un nombre para el vuelo"), findsNothing);
    var verifier =
        verify(client.get(captureAny, headers: captureAnyNamed("headers")));
    expect(verifier.captured[0], "http://droneapp.ngrok.io/api/flights");
    expect(
        verifier.captured[1], containsPair("Authorization", "Token faketoken"));
  });*/
}
