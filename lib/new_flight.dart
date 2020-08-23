import 'package:flutter/material.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter_app/waiting_flights_widget.dart';
import 'package:intl/intl.dart';
import 'api.dart';
import 'models/flight.dart';

class NewFlightWidget extends StatelessWidget {
  static const routeName = "/flights/new";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear vuelo"),
      ),
      body: NewFlightForm(),
    );
  }
}

class NewFlightForm extends StatefulWidget {
  @override
  NewFlightFormState createState() => NewFlightFormState();
}

class NewFlightFormState extends State<NewFlightForm> {
  final _formKey = GlobalKey<FormState>();
  String _name, _description;
  Camera camera;
  DateTime _date;
  bool _success = true;

  final format = DateFormat("yyyy-MM-dd");

  String isNotEmptyValidator(String message, String value) =>
      value.isEmpty ? message : null;

  String nameValidator(value) =>
      isNotEmptyValidator('Escriba un nombre para el vuelo', value);

  String descriptionValidator(value) =>
      isNotEmptyValidator("Escriba una descripción", value);

  String dateValidator(value) => value == null ? "Seleccione una fecha" : null;

  String cameraValidator(Camera value) =>
      value == null ? "Seleccione una cámara" : null;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(children: <Widget>[
              if (!_success)
                Text(
                  "Error al crear vuelo!",
                  style: TextStyle(color: Colors.red),
                ),
              TextFormField(
                  validator: nameValidator,
                  decoration: InputDecoration(
                      hintText: "Nombre del vuelo", labelText: "Nombre"),
                  onSaved: (val) => _name = val),
              DateTimeField(
                decoration: const InputDecoration(
//                  icon: const Icon(Icons.calendar_today),
                  hintText: 'Escriba la fecha del vuelo',
                  labelText: 'Fecha',
                ),
                onSaved: (val) => _date = val,
                format: format,
                onShowPicker: (context, currentValue) {
                  return showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      initialDate: currentValue ?? DateTime.now(),
                      lastDate: DateTime(2100));
                },
                validator: dateValidator,
              ),
              DropdownButtonFormField<Camera>(
                key: Key("camera-dropdown"),
                value: camera,
                items: Camera.values
                    .map((camera) => DropdownMenuItem(
                          value: camera,
                          child: Text(CameraHelper.description(camera)),
                        ))
                    .toList(),
                onChanged: (newValue) => setState(() => camera = newValue),
                decoration: const InputDecoration(
                  hintText: 'Seleccione la cámara usada',
                  labelText: 'Cámara',
                ),
                validator: cameraValidator,
              ),
              TextFormField(
                keyboardType: TextInputType.multiline,
                maxLines: 6,
                validator: descriptionValidator,
                decoration: InputDecoration(
                    hintText: "Descripción, notas, etc.",
                    labelText: "Descripción"),
                onSaved: (val) => _description = val,
              ),
              RaisedButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();

                    Flight f = Flight(
                        name: _name, description: _description, date: _date);

                    var success = await Api.tryCreateFlight(f);
                    setState(() => _success = success);
                    if (_success)
                      Navigator.pushReplacementNamed(
                          context, WaitingFlightsWidget.routeName);
                  }
                },
                child: Text('Crear vuelo'),
              ),
            ])));
  }
}
