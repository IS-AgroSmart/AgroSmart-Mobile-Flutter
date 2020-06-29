import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight.dart';
import 'package:flutter_app/results.dart';
import 'package:photo_view/photo_view.dart';

import 'api.dart';

class OrthomosaicPreviewWidget extends StatefulWidget {
  static final String routeName = "/flights/orthomosaic";

  @override
  _OrthomosaicPreviewWidgetState createState() =>
      _OrthomosaicPreviewWidgetState();
}

class _OrthomosaicPreviewWidgetState extends State<OrthomosaicPreviewWidget> {
  Flight flight;

  @override
  void initState() {
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
        body: PhotoView(
            imageProvider: NetworkImage(
                "${Api.ENTRYPOINT}/downloads/${flight.uuid}/orthomosaic.png",
                scale: 1.0)));
  }
}

enum FlightResult { ORTHOMOSAIC, MODEL3D, CLOUD }

class FlightResultsHelper {
  static String description(FlightResult r) => {
        FlightResult.ORTHOMOSAIC: "Ortomosaico",
        FlightResult.MODEL3D: "Modelo 3D"
      }[r];
}
