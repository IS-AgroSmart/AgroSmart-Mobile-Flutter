import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/admin_options.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/user_requests.dart';
import 'package:flutter_app/users_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.dart';

void main() {
  var widget, mockObserver, client;
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(
      {"token": "faketoken", "username": "foo"});

  setUp(() {
    client = MockClient();
    Api.client = client;
    when(client.get("http://droneapp.ngrok.io/api/users",
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode([]), 200));

    mockObserver = MockNavigatorObserver();

    final key = GlobalKey<NavigatorState>();
    widget = MaterialApp(
      home: AdminOptionsWidget(),
      navigatorKey: key,
      navigatorObservers: [mockObserver],
      routes: {
        UserRequestsWidget.routeName: (context) => UserRequestsWidget(),
        UsersWidget.routeName: (context) => UsersWidget(),
      },
    );
  });

  testWidgets('AdminOptionsWidget has a title and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);

    expect(find.text("Opciones Admin"), findsOneWidget);
    expect(find.byType(RaisedButton), findsNWidgets(3));
  });

  testWidgets("AdminOptionsWidget navigates to User Requests",
      (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(UserRequestsWidget), findsNothing);
    var requestsButton = find.widgetWithText(RaisedButton, "Solicitudes");
    expect(requestsButton, findsOneWidget);
    await tester.tap(requestsButton);
    await tester.pumpAndSettle();

    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(UserRequestsWidget), findsOneWidget);
  });

  testWidgets("LoginWidget navigates to Users", (WidgetTester tester) async {
    await tester.pumpWidget(widget);
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    expect(find.byType(UsersWidget), findsNothing);
    var requestsButton = find.widgetWithText(RaisedButton, "Usuarios");
    expect(requestsButton, findsOneWidget);
    await tester.tap(requestsButton);
    await tester.pumpAndSettle();

    verify(mockObserver.didReplace(
        newRoute: anyNamed("newRoute"), oldRoute: anyNamed("oldRoute")));
    expect(find.byType(UsersWidget), findsOneWidget);
  });

  testWidgets("routeNameFunc() returns correct route",
      (WidgetTester tester) async {
    expect(AdminOptionsWidget().routeNameFunc(), "/admin_options");
  });
}
