import 'package:flutter_app/_abstract_flights_widget.dart';

import 'api.dart';

class DeletedFlightsWidget extends AbstractFlightsWidget {
  static const routeName = "/flights/deleted";

  @override
  String routeNameFunc() => routeName;

  @override
  _DeletedFlightsWidgetState createState() => _DeletedFlightsWidgetState();
}

class _DeletedFlightsWidgetState extends AbstractFlightsState {
  final appTitle = "Vuelos eliminados";
  final deleteMessage = "¿Confirma que desea eliminar el vuelo?\n Una vez eliminado no podrá recuperarlo.";
  final detailOnClick = false;

  @override
  void initState() {
    flightsFutureCallable = Api.fetchDeletedFlights;
    super.initState();
  }
}
