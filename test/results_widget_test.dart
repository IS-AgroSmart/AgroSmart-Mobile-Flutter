import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
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
}
