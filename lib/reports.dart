import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight.dart';

import 'api.dart';
import 'orthomosaic_preview.dart';

class ReportsWidgetArguments {
  final Flight flight;

  ReportsWidgetArguments(this.flight);
}

class ReportsWidget extends StatefulWidget {
  static final String routeName = "/flights/reports";

  @override
  _ReportsWidgetState createState() => _ReportsWidgetState();
}

class _ReportsWidgetState extends State<ReportsWidget> {
  Flight flight;
  Future<List<FlightResult>> _future;
  Map<String, bool> values = {
    '3d': false,
    'cloud': false,
    'mosaico': false,
    'generales': false,
    'ndvi': false,
  };

  @override
  void initState() {
    _future = Api.getAvailableResults(flight);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ReportsWidgetArguments args =
        ModalRoute.of(context).settings.arguments;
    flight = args.flight;

    return Scaffold(
        appBar: AppBar(
          title: Text("Descarga reporte: ${flight.name}"),
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
                      children: <Widget>[
                        Text(
                          "Elegir datos del reporte",
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        CheckboxListTile(
                          title: Text("Datos generales"),
                          value: values['generales'],
                          onChanged: (newValue) {
                            setState(() {
                              values['generales'] = newValue;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                        ),
                        CheckboxListTile(
                          title: Text("Ortomosaico"),
                          value: values['mosaico'],
                          onChanged: (newValue) {
                            setState(() {
                              values['mosaico'] = newValue;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                        ),
                        CheckboxListTile(
                          title: Text("Detalles Nube de puntos"),
                          value: values['cloud'],
                          onChanged: flight.camera != "RGB"? (newValue) {
                            setState(() {
                              values['cloud'] = newValue;
                            });
                          }: null,
                          selected: false,
                          controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                        ),
                        CheckboxListTile(
                          title: Text("Detalles Modelo 3D"),
                          value: values['3d'],
                          onChanged: flight.camera != "RGB"? (newValue) {
                            setState(() {
                              values['3d'] = newValue;
                            });
                          }: null,
                          controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                        ),
                        CheckboxListTile(
                          title: Text("Ortomosaico NDVI"),
                          value: values['ndvi'],
                          onChanged: flight.camera != "RGB"? (newValue) {
                            setState(() {
                              values['ndvi'] = newValue;
                            });
                          }: null,
                          controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                        ),
                        RaisedButton(
                            child: Text("Reporte"),
                            onPressed: () async => Api.downloadReport(flight, values)),
                      ],
                    );
                  } else
                    return Center(child: CircularProgressIndicator());
                })));
  }
}

