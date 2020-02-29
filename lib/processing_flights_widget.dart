import 'package:flutter_app/_abstract_flights_widget.dart';

import 'api.dart';

class ProcessingFlightsWidget extends AbstractFlightsWidget {
  static const routeName = "/flights/processing";

  @override
  String routeNameFunc() => ProcessingFlightsWidget.routeName;

  @override
  _ProcessingFlightsState createState() => _ProcessingFlightsState();
}

class _ProcessingFlightsState extends AbstractFlightsState {
  final appTitle = "Vuelos en procesamiento";

  @override
  void initState() {
    flightsFutureCallable = Api.fetchProcessingFlights;
    super.initState();
  }
}
