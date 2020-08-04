
import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_app/reports.dart';
import 'package:flutter_app/results.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
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

  var mockObserver;

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
    mockObserver = MockNavigatorObserver();


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
        navigatorObservers: [mockObserver],
        routes: {ReportsWidget.routeName: (context) => ReportsWidget()},
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

  testWidgets('ResultsWidget has a title', (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: ResultsWidgetArguments(flight), child: ResultsWidget());

    expect(find.text("Resultados: Flight name"), findsOneWidget);
  });

  testWidgets('ResultsWidget has Download and Report buttons',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: ResultsWidgetArguments(flight), child: ResultsWidget());

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text("Descargar"), findsOneWidget);
    expect(find.text("Reporte"), findsOneWidget);
  });

  testWidgets('ResultsWidget Report button redirects to another screen',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: ResultsWidgetArguments(flight), child: ResultsWidget());
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(ReportsWidget), findsNothing);

    await tester.tap(find.text("Reporte"));
    await tester.pumpAndSettle();

    verify(mockObserver.didPush(any, any));
    expect(find.byType(ReportsWidget), findsOneWidget);
  });

//  testWidgets('Drawer shows user email', (WidgetTester tester) async {
//    await tester.pumpWidget(widget);
//
//    expect(find.text(Helpers.loggedInUser.email), findsOneWidget);
//  });
//
//  testWidgets("Drawer navigates to Create Flight", (WidgetTester tester) async {
//    await tester.pumpWidget(widget);
//    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation
//
//    expect(find.byType(NewFlightWidget), findsNothing);
//    await tester.tap(find.text("Crear nuevo vuelo"));
//    await tester.pumpAndSettle();
//    verify(mockObserver.didReplace(
//        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
//    expect(find.byType(NewFlightWidget), findsOneWidget);
//  });
//
//  testWidgets("Drawer navigates to Completed Flights",
//      (WidgetTester tester) async {
//    await tester.pumpWidget(widget);
//    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation
//
//    expect(find.byType(CompletedFlightsWidget), findsNothing);
//    await tester.tap(find.text("Vuelos completos"));
//    await tester.pumpAndSettle();
//    verify(mockObserver.didReplace(
//        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
//    expect(find.byType(CompletedFlightsWidget), findsOneWidget);
//  });
//
//  testWidgets("Drawer navigates to Processing Flights",
//      (WidgetTester tester) async {
//    await tester.pumpWidget(widget);
//    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation
//
//    expect(find.byType(ProcessingFlightsWidget), findsNothing);
//    await tester.tap(find.text("Vuelos en procesamiento"));
//    await tester.pumpAndSettle();
//    verify(mockObserver.didReplace(
//        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
//    expect(find.byType(ProcessingFlightsWidget), findsOneWidget);
//  });
//
//  testWidgets("Drawer navigates to Waiting Flights",
//      (WidgetTester tester) async {
//    await tester.pumpWidget(widget);
//    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation
//
//    expect(find.byType(WaitingFlightsWidget), findsNothing);
//    await tester.tap(find.text("Vuelos pendientes"));
//    await tester.pumpAndSettle();
//    verify(mockObserver.didReplace(
//        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
//    expect(find.byType(WaitingFlightsWidget), findsOneWidget);
//  });
//
//  testWidgets("Drawer navigates to Deleted Flights",
//      (WidgetTester tester) async {
//    await tester.pumpWidget(widget);
//    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation
//
//    expect(find.byType(DeletedFlightsWidget), findsNothing);
//    await tester.tap(find.text("Vuelos eliminados"));
//    await tester.pumpAndSettle();
//    verify(mockObserver.didReplace(
//        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
//    expect(find.byType(DeletedFlightsWidget), findsOneWidget);
//  });
}
