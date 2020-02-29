import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight.dart';

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
                    List<FlightResult> results = snapshot.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
//                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
//                        Text(flight.name,
//                            style: Theme.of(context).textTheme.title),
                        for (final r in results)
                          RaisedButton(
                              child: Text(FlightResultsHelper.description(r)),
                              onPressed: () async => Api.download(flight, r)),
                      ],
                    );
                  } else
                    return Center(child: CircularProgressIndicator());
                })));
  }
}

//enum FlightResults { ORTHOMOSAIC, MODEL3D }
