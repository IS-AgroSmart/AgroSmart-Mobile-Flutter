import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_app/orthomosaic_preview.dart';
import 'package:flutter_app/results.dart';

import 'api.dart';

class FlightDetailWidget extends StatefulWidget {
  final Flight flight;

  FlightDetailWidget({Key key, @required this.flight}) : super(key: key);

  @override
  State createState() => _FlightDetailWidgetState(flight);
}

class _FlightDetailWidgetState extends State<FlightDetailWidget> {
  final Flight flight;
  StreamController<Flight> _flightStream;

  _FlightDetailWidgetState(this.flight);

  @override
  void initState() {
    super.initState();

    _flightStream = StreamController<Flight>();
    _updateFlight();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(flight.name),
        ),
        body: StreamBuilder<Flight>(
            stream: _flightStream.stream,
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.red),
                );
              if (snapshot.hasData) {
                var updatedFlight = snapshot.data;
                return RefreshIndicator(
                    onRefresh: () async => _updateFlight(),
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: <Widget>[
                            Text(
                              "Nombre",
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            Text(
                              updatedFlight.name,
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Fecha de creación",
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            Text(
                              Flight.flightOutputFormatter
                                  .format(updatedFlight.date),
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Tiempo de procesamiento",
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            Text(
                              updatedFlight.humanizedProcessingTime(),
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Notas",
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            Text(
                              updatedFlight.description,
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                            SizedBox(height: 10),
                            if (updatedFlight.state == FlightState.COMPLETE)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  RaisedButton(
                                    child: Text("Resultados"),
                                    onPressed: () => Navigator.pushNamed(
                                        context, ResultsWidget.routeName,
                                        arguments: ResultsWidgetArguments(
                                            updatedFlight)),
                                  ),
                                  RaisedButton(
                                    child: Text("Mosaico"),
                                    onPressed: () => Navigator.pushNamed(
                                        context,
                                        OrthomosaicPreviewWidget.routeName,
                                        arguments: ResultsWidgetArguments(
                                            updatedFlight)),
                                  )
                                ],
                              ),
                            if (updatedFlight.state == FlightState.PROCESSING)
                              Column(
                                children: <Widget>[
                                  Text(
                                      "${updatedFlight.progress.toString()} % (falta ${updatedFlight.humanizeTimeLeft()})"),
                                  SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: updatedFlight.progress / 100.0,
                                  ),
                                  RaisedButton(
                                    onPressed: () async => _cancelFlight(),
                                    child: Text('Cancelar'),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                          ],
                        )));
              } else
                return Center(child: CircularProgressIndicator());
            }));
  }

  Future<void> _cancelFlight() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Esta a punto de cancelar el procesamiento..'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Realmente desea cancelar el procesamiento del vuelo?'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Si'),
              textColor: Colors.red,
              onPressed: () async => _cancelFlightAction(),
            ),
          ],
        );
      },
    );
  }

  void _cancelFlightAction() async {
    Api.cancelProcessingFlights(this.flight);
    Navigator.of(context).pop();
  }

  void _updateFlight() async {
    var flights = await Api.fetchFlightDetails(this.flight);
    _flightStream.add(flights);
  }
}
