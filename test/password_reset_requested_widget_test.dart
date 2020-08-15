
import 'package:flutter/material.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/models/user.dart';
import 'package:flutter_app/password_reset_requested_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.dart';

void main() {
  SharedPreferences.setMockInitialValues(
      {"token": "faketoken", "username": "foo"});
  Helpers.loggedInUser = User(
      pk: 2,
      username: "notdemo",
      name: "Not Demo User",
      email: "notdemo@example.com",
      organization: "Acme Corp",
      isStaff: false,
      type: "ACTIVE");
  var mockObserver;
  setUp(() {
    mockObserver = MockNavigatorObserver();
//    widget =
//        MaterialApp(home: PasswordResetRequestedWidget(), navigatorObservers: [
//      mockObserver
//    ], routes: {
//      Profile.routeName: (context) => Profile(),
//    });
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

  testWidgets('PasswordResetRequestedWidget has a title and button',
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: PasswordResetRequestedWidget());

    expect(find.byType(RaisedButton), findsOneWidget);
    expect(find.text("Recuperar Contraseña"), findsOneWidget);
    expect(find.text("Recuperación de contraseña solicitada"), findsOneWidget);
    expect(find.text("Revise su email para recuperar la contraseña."),
        findsOneWidget);
  });

  testWidgets("PasswordResetRequestedWidget goes back on OK",
      (WidgetTester tester) async {
    await pumpArgumentWidget(tester,
        args: null, child: PasswordResetRequestedWidget());
    verify(mockObserver.didPush(any, any)); // HACK: Flush the first navigation

    await tester.tap(find.byType(RaisedButton).last);
    await tester.pumpAndSettle();

    verify(mockObserver.didPop(any, any));
    expect(find.byType(FlatButton), findsOneWidget);
  });
}
