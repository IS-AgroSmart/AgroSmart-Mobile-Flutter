import 'package:flutter/material.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/login_widget.dart';
import 'package:flutter_app/new_flight.dart';
import 'package:flutter_app/orthomosaic_preview.dart';
import 'package:flutter_app/processing_flights_widget.dart';
import 'package:flutter_app/results.dart';
import 'package:flutter_app/waiting_flights_widget.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();
  await initializeDateFormatting('es_ES', null);

  if ((await Api.getToken()) != null) await Api.fetchUserDetails();
  runApp(MyNewApp());
}

class MyNewApp extends StatefulWidget {
  @override
  State<MyNewApp> createState() => _AppState();
}

class _AppState extends State<MyNewApp> {
  bool _loggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter App",
      home: _loggedIn ? CompletedFlightsWidget() : LoginWidget(),
      routes: {
        LoginWidget.routeName: (context) => LoginWidget(),
        CompletedFlightsWidget.routeName: (context) => CompletedFlightsWidget(),
        ResultsWidget.routeName: (context) => ResultsWidget(),
        OrthomosaicPreviewWidget.routeName: (context) =>
            OrthomosaicPreviewWidget(),
        ProcessingFlightsWidget.routeName: (context) =>
            ProcessingFlightsWidget(),
        WaitingFlightsWidget.routeName: (context) => WaitingFlightsWidget(),
        NewFlightWidget.routeName: (context) => NewFlightWidget(),
      },
//      theme: ThemeData(primarySwatch: Colors.green),
    );
  }

  @override
  void initState() {
    super.initState();
    Api.getToken()
        .then((result) => setState(() => _loggedIn = (result != null)));
  }
}
