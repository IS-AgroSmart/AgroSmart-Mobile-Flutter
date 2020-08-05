
import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_app/reports.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


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


  var flight = Flight(
      name: "Flight name",
      deleted: false,
      camera: "RGB",
      date: DateTime(2020),
      description: "Flight description",
      processingTime: 60 * 1000,
      progress: 100,
      state: FlightState.COMPLETE,
      uuid: "fakeuuid");

  setUp(() {

//    client = MockClient();
//    Api.client = client;
//    when(client.get(any, headers: anyNamed("headers")))
//        .thenAnswer((_) async => http.Response(jsonEncode([]), 200));
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

  testWidgets('ReportsWidget has a title', (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: ReportsWidgetArguments(flight), child: ReportsWidget());

    expect(find.text("Descarga reporte: Flight name"), findsOneWidget);
  });

  testWidgets('ResultsWidget has Download button', (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: ReportsWidgetArguments(flight), child: ReportsWidget());

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text("Reporte"), findsOneWidget);
  });

  testWidgets(
      'ResultsWidget Download button shows error message if no sections selected',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: ReportsWidgetArguments(flight), child: ReportsWidget());

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text("Error"), findsNothing);
    expect(
        find.text("Escoja al menos una sección para el reporte"), findsNothing);
    await tester.tap(find.text("Reporte"));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text("Error"), findsOneWidget);
    expect(find.text("Escoja al menos una sección para el reporte"),
        findsOneWidget);
  });

  testWidgets('Can dismiss alert dialog if no sections were selected',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: ReportsWidgetArguments(flight), child: ReportsWidget());

    await tester.tap(find.text("Reporte"));
    await tester.pumpAndSettle();

    expect(find.text("OK"), findsOneWidget);

    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
    expect(find.text("OK"), findsNothing);
  });

  testWidgets('Can select sections for the report',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: ReportsWidgetArguments(flight), child: ReportsWidget());

    await tester.tap(find.text("Datos generales"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reporte"));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
