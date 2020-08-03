
import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_app/new_flight.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  var widget;
  setUp(() {
    widget = MaterialApp(home: NewFlightWidget());
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
}
