import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_app/reports.dart';

import 'api.dart';
import 'orthomosaic_preview.dart';

class ResultsWidgetArguments {
  final Flight flight;

  ResultsWidgetArguments(this.flight);
}

class ResultsWidget extends StatefulWidget {
  static final String routeName = "/flights/results";

  @override
  _ResultsWidgetState createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget> {
  Flight flight;
  Future<List<FlightResult>> _future;
  Map<String, bool> values = {'3d': true, 'cloud': false, 'mosaico': false};

  @override
  void initState() {
    _future = Api.getAvailableResults(flight);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ResultsWidgetArguments args =
        ModalRoute.of(context).settings.arguments;
    flight = args.flight;

    return Scaffold(
        appBar: AppBar(
          title: Text("Resultados: ${flight.name}"),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<List<FlightResult>>(
                future: _future,
                builder: (BuildContext context,
                    AsyncSnapshot<List<FlightResult>> snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      //crossAxisAlignment: CrossAxisAlignment.stretch,
//                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CheckboxListTile(
                          title: Text("Modelo 3D"),
                          value: values['3d'],
                          onChanged: (newValue) {
                            setState(() {
                              values['3d'] = newValue;
                            });
                          },
                          controlAffinity: ListTileControlAffinity
                              .leading, //  <-- leading Checkbox
                        ),
                        CheckboxListTile(
                          title: Text("Nube de puntos"),
                          value: values['cloud'],
                          onChanged: flight.camera != "RGB"? (newValue) {
                            setState(() {
                              values['cloud'] = newValue;
                            });
                          }: null,
                          selected: false,
                          controlAffinity: ListTileControlAffinity
                              .leading, //  <-- leading Checkbox
                        ),
                        CheckboxListTile(
                          title: Text("Ortomosaico"),
                          value: values['mosaico'],
                          onChanged: (newValue) {
                            setState(() {
                              values['mosaico'] = newValue;
                            });
                          },
                          controlAffinity: ListTileControlAffinity
                              .leading, //  <-- leading Checkbox
                        ),
                        Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              RaisedButton(
                                  child: Text("Descargar"),
                                  onPressed: () async =>
                                      Api.downloadList(flight, values)),
                              RaisedButton(
                                  child: Text("Reporte"),
                                  onPressed: () => Navigator.pushNamed(
                                      context, ReportsWidget.routeName,
                                      arguments:
                                          ReportsWidgetArguments(flight))
                              ),
                            ]
                        )
                      ],
                    );
                  } else
                    return Center(child: CircularProgressIndicator());
                })));
  }
}

//enum FlightResults { ORTHOMOSAIC, MODEL3D }
