import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/api.dart';
import 'package:flutter_app/flight_detail_widget.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_app/orthomosaic_preview.dart';
import 'package:flutter_app/results.dart';
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

  var completeResponse, inProgressResponse;
  var client, mockObserver;

  setUp(() {
    completeResponse = {
      "uuid": "uuidfoo",
      "name": "flightname",
      "annotations": "some notes",
      "date": "2020-01-01",
      "processing_time": 6000,
      "state": "COMPLETE",
      "nodeodm_info": {
        "progress": 100,
      },
      "camera": "RGB",
      "deleted": false
    };
    inProgressResponse = {
      "uuid": "uuidfoo",
      "name": "flightname",
      "annotations": "some notes",
      "date": "2020-01-01",
      "processing_time": 1000 * 60 * 4,
      "state": "PROCESSING",
      "nodeodm_info": {
        "progress": 40,
      },
      "camera": "RGB",
      "deleted": false
    };
//    canceledResponse = {
//      "uuid": "uuidfoo",
//      "name": "flightname",
//      "annotations": "some notes",
//      "date": "2020-01-01",
//      "processing_time": 1000 * 60 * 4,
//      "state": "CANCELED",
//      "nodeodm_info": {
//        "progress": 40,
//      },
//      "camera": "RGB",
//      "deleted": false
//    };

    client = MockClient();
    Api.client = client;
    when(client.get(any, headers: anyNamed("headers"))).thenAnswer(
        (_) async => http.Response(jsonEncode(completeResponse), 200));

    mockObserver = MockNavigatorObserver();
    client = MockClient();
    Api.client = client;
  });

  void _mockResponse(dynamic resp) {
    when(client.get("http://droneapp.ngrok.io/api/flights/" + resp["uuid"],
            headers: anyNamed("headers")))
        .thenAnswer((_) async => http.Response(jsonEncode(resp), 200));
  }

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
        routes: {
          ResultsWidget.routeName: (context) => ResultsWidget(),
          OrthomosaicPreviewWidget.routeName: (context) =>
              OrthomosaicPreviewWidget()
        },
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

  testWidgets('FlightDetailWidget has a title', (WidgetTester tester) async {
    _mockResponse(completeResponse);
    await pumpArgumentWidget(tester,
        args: null,
        child: FlightDetailWidget(flight: Flight.fromMap(completeResponse)));
    expect(find.text("flightname"), findsNWidgets(2)); // title and in text
  });

  testWidgets('FlightDetailWidget shows results buttons on Complete flight',
      (WidgetTester tester) async {
    _mockResponse(completeResponse);
    await pumpArgumentWidget(tester,
        args: null,
        child: FlightDetailWidget(flight: Flight.fromMap(completeResponse)));
    expect(find.widgetWithText(RaisedButton, "Resultados"), findsOneWidget);
    expect(find.widgetWithText(RaisedButton, "Mosaico"), findsOneWidget);
  });

  testWidgets('Results button navigates to FlightResults',
      (WidgetTester tester) async {
    _mockResponse(completeResponse);
    await pumpArgumentWidget(tester,
        args: null,
        child: FlightDetailWidget(flight: Flight.fromMap(completeResponse)));

    expect(find.byType(ResultsWidget), findsNothing);

    await tester.tap(find.widgetWithText(RaisedButton, "Resultados"));
    await tester.pumpAndSettle();

    verify(mockObserver.didPush(any, any));
    expect(find.byType(ResultsWidget), findsOneWidget);
  });

  testWidgets('Mosaic button navigates to Orthomosaic',
      (WidgetTester tester) async {
    HttpOverrides.runZoned(() async {
      when(client.get(
              "http://droneapp.ngrok.io/api/downloads/uuidfoo/orthomosaic.png",
              headers: anyNamed("headers")))
          .thenAnswer((_) async => http.Response("", 200));
      _mockResponse(completeResponse);
      await pumpArgumentWidget(tester,
          args: null,
          child: FlightDetailWidget(flight: Flight.fromMap(completeResponse)));

      expect(find.byType(OrthomosaicPreviewWidget), findsNothing);

      await tester.tap(find.widgetWithText(RaisedButton, "Mosaico"));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(OrthomosaicPreviewWidget), findsOneWidget);
    }, createHttpClient: createMockImageHttpClient);
  });

  testWidgets(
      "FlightDetailWidget doesn't show results buttons on Processing flight",
      (WidgetTester tester) async {
    _mockResponse(inProgressResponse);
    await pumpArgumentWidget(tester,
        args: null,
        child: FlightDetailWidget(flight: Flight.fromMap(inProgressResponse)));
    expect(find.widgetWithText(RaisedButton, "Resultados"), findsNothing);
    expect(find.widgetWithText(RaisedButton, "Mosaico"), findsNothing);

    expect(find.text("40.0 % (falta 0 h, 6 min)"), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets("Cancel button shows modal to cancel",
      (WidgetTester tester) async {
    _mockResponse(inProgressResponse);
    await pumpArgumentWidget(tester,
        args: null,
        child: FlightDetailWidget(flight: Flight.fromMap(inProgressResponse)));

    var rejectButton = find.widgetWithText(RaisedButton, "Cancelar");
    expect(find.text("¿Realmente desea cancelar el procesamiento del vuelo?"),
        findsNothing);
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();
    expect(find.text("¿Realmente desea cancelar el procesamiento del vuelo?"),
        findsOneWidget);

    await tester.tap(find.text("No"));
    await tester.pumpAndSettle();
    expect(find.text("¿Realmente desea cancelar el procesamiento del vuelo?"),
        findsNothing);
  });

  // Gets stuck on infinite loop waiting for API to return CANCELED
  /*testWidgets("FlightDetailWidget cancels flight", (WidgetTester tester) async {
    when(client.post(any, headers: anyNamed("headers"), body: anyNamed("body")))
        .thenAnswer((_) async => http.Response("", 200));
    _mockResponse(inProgressResponse);
    await pumpArgumentWidget(tester,
        args: null,
        child: FlightDetailWidget(flight: Flight.fromMap(inProgressResponse)));

    var rejectButton = find.widgetWithText(RaisedButton, "Cancelar");
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Sí"));
    await tester.pumpAndSettle(Duration(milliseconds: 100));
    reset(client);
    _mockResponse(canceledResponse);
    await tester.pumpAndSettle();

    var verifier = verify(client.post(captureAny,
        headers: captureAnyNamed("headers"), body: captureAnyNamed("body")));
    expect(
        verifier.captured[0], "http://droneapp.ngrok.io/nodeodm/task/cancel/");
    expect(verifier.captured[1],
        isNot(containsPair("Authorization", "Token faketoken")));
    expect(jsonDecode(verifier.captured[2]), containsPair("uuid", "uuidfoo"));
  });*/
}

MockHttpClient createMockImageHttpClient(SecurityContext _) {
  final MockHttpClient client = new MockHttpClient();
  final MockHttpClientRequest request = new MockHttpClientRequest();
  final MockHttpClientResponse response = new MockHttpClientResponse();
  final MockHttpHeaders headers = new MockHttpHeaders();
  when(client.getUrl(any))
      .thenAnswer((_) => new Future<HttpClientRequest>.value(request));
  when(request.headers).thenReturn(headers);
  when(request.close())
      .thenAnswer((_) => new Future<HttpClientResponse>.value(response));
  when(response.contentLength).thenReturn(kTransparentImage.length);
  when(response.statusCode).thenReturn(HttpStatus.ok);
  when(response.listen(any)).thenAnswer((Invocation invocation) {
    final void Function(List<int>) onData = invocation.positionalArguments[0];
    final void Function() onDone = invocation.namedArguments[#onDone];
    final void Function(Object, [StackTrace]) onError =
        invocation.namedArguments[#onError];
    final bool cancelOnError = invocation.namedArguments[#cancelOnError];
    return new Stream<List<int>>.fromIterable(<List<int>>[kTransparentImage])
        .listen(onData,
            onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  });
  return client;
}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class MockHttpHeaders extends Mock implements HttpHeaders {}

const List<int> kTransparentImage = const <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
];
