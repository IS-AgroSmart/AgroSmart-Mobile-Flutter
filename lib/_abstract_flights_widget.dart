import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/new_flight.dart';

import 'api.dart';
import 'drawer.dart';
import 'flight_detail_widget.dart';
import 'models/flight.dart';

abstract class AbstractFlightsWidget extends StatefulWidget {
  static const routeName = "declare on child classes";

  String routeNameFunc();
}

abstract class AbstractFlightsState extends State<AbstractFlightsWidget> {
  Future<List<Flight>> Function() flightsFutureCallable;
  Future<List<Flight>> flightsFuture;
  StreamController<List<Flight>> _flightsStream;
  List<Flight> flights;

  String appTitle;

  bool detailOnClick = true;
  String deleteMessage = "";

  @override
  void initState() {
    flightsFuture = flightsFutureCallable();
    _flightsStream = StreamController<List<Flight>>();
    _loadFlights();
    super.initState();
  }

  void _loadFlights() async {
    var flights = await flightsFutureCallable();
    _flightsStream.add(flights);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(appTitle),
        ),
        drawer: AppDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, NewFlightWidget.routeName),
          child: Icon(Icons.add),
        ),
        body: StreamBuilder<List<Flight>>(
          stream: _flightsStream.stream,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Text(
                snapshot.error.toString(),
                style: TextStyle(color: Colors.red),
              );
            if (snapshot.hasData && snapshot.data.isNotEmpty) {
              var _context = context;
              return RefreshIndicator(
                  onRefresh: () async => _loadFlights(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) {
                      final flight = snapshot.data[index];
                      var icon;
                      switch (flight.state) {
                        case FlightState.COMPLETE:
                          icon = Icon(Icons.check);
                          break;
                        case FlightState.ERROR:
                          icon = Icon(Icons.error);
                          break;
                        case FlightState.CANCELED:
                          icon = Icon(Icons.cancel);
                          break;
                        case FlightState.PROCESSING:
                          icon = Container(
                            width: 25,
                            height: 25,
                            // can be whatever value you want
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              value: flight.progress / 100,
                            ),
                          );
                          break;
                        default:
                          icon = Icon(Icons.map);
                          break;
                      }
                      return ListTile(
                          title: Text('${flight.name}'),
                          subtitle: Text(
                              Flight.flightOutputFormatter.format(flight.date)),
                          leading: icon,
                          trailing: deleteMessage.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("Confirmar eliminación"),
                                      content: Text(deleteMessage),
                                      actions: <Widget>[
                                        new FlatButton(
                                          child: new Text("Cancelar"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        new FlatButton(
                                          child: new Text(
                                            "Eliminar",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onPressed: () {
                                            Scaffold.of(_context).showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Eliminando vuelo. Espere...')));
                                            Navigator.of(context).pop();
                                            Api.tryDeleteFlight(flight).then(
                                                (_) async => _loadFlights());
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              // HACK: Placeholder to NOT show Delete button
                              : Container(width: 1, height: 1),
                          onTap: () async {
                            if (detailOnClick) {
                              // await Navigator.push returns when FlightDetailWidget gets popped, time to reload flights
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          FlightDetailWidget(flight: flight)));
                              _loadFlights();
                            }
                          });
                    },
                  ));
            } else if (snapshot.hasData && snapshot.data.isEmpty)
              return Center(child: Text("No hay ${appTitle.toLowerCase()}"));
            else
              return Center(child: CircularProgressIndicator());
          },
        ));
  }
}
