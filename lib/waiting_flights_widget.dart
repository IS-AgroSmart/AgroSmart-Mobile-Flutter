import 'package:flutter_app/_abstract_flights_widget.dart';

import 'api.dart';

class WaitingFlightsWidget extends AbstractFlightsWidget {
  static const routeName = "/flights/waiting";

  @override
  String routeNameFunc() => routeName;

  @override
  _WaitingFlightsWidgetState createState() => _WaitingFlightsWidgetState();
}

class _WaitingFlightsWidgetState extends AbstractFlightsState {
  final appTitle = "Vuelos pendientes";

  @override
  void initState() {
    flightsFutureCallable = Api.fetchWaitingFlights;
    super.initState();
  }
}
