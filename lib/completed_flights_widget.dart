import '_abstract_flights_widget.dart';
import 'api.dart';

class CompletedFlightsWidget extends AbstractFlightsWidget {
  static const routeName = "/flights/complete";

  @override
  String routeNameFunc() => CompletedFlightsWidget.routeName;

  @override
  _CompletedFlightsState createState() => _CompletedFlightsState();
}

class _CompletedFlightsState extends AbstractFlightsState {
  final appTitle = "Vuelos completos";
  final deleteMessage = "¿Confirma que desea eliminar el vuelo?\n Podrá recuperarlo durante 30 días.";

  @override
  void initState() {
    flightsFutureCallable = Api.fetchCompleteOrErroredFlights;
    super.initState();
  }
}
